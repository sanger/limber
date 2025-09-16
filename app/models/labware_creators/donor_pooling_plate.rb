# frozen_string_literal: true

module LabwareCreators
  # This labware creator receives barcodes for a configured number of source
  # plates from the user. It pools samples from the passed wells into a
  # destination plate. It's used for scRNA Donor Pooling to create 'LRC PBMC
  # Pools' plates from 'LRC PBMC Defrost PBS' plates.
  #
  # The creator imposes restrictions:
  # - It doesn't allow combining samples from different studies or projects.
  # - It doesn't allow samples with the same donor_id in the same pool.
  # - All wells must have cell count data unless they are failed.
  # - The number of pools must not exceed the number configured for the samples.
  #
  # The number of pools is determined by a lookup table based on sample count.
  # Tag depth index is added to aliquot attributes to avoid tag clashes.
  class DonorPoolingPlate < Base
    include LabwareCreators::CustomPage
    include CreatableFrom::PlateOnly

    include LabwareCreators::DonorPoolingCalculator
    include LabwareCreators::DonorPoolingValidator

    # The name of the template that will be used for rendering the barcode
    # input page.
    self.page = 'donor_pooling_plate'

    # Add the barcodes attribute to the list of attributes for this class.
    # It is used by the creation controller to permit the barcodes parameter.
    self.attributes += [{ barcodes: [] }]

    # @!attribute [r] barcodes
    #   @return [Array<String>] an array of barcode strings from the user
    attr_reader :barcodes

    # @!attribute [r] minimal_barcodes
    #   @return [Array<String>] a version of barcodes where any blank values
    #     have been removed and remaining values have been stripped of leading
    #     and trailing whitespace
    attr_reader :minimal_barcodes

    # Define related objects to be included when retrieving source plates using
    # the Sequencescape::API::V2.Plate.find_all method. The 'includes' argument
    # of the method is expected to be an array of strings.
    SOURCE_PLATE_INCLUDES = %w[
      purpose
      wells.aliquots.study
      wells.aliquots.project
      wells.aliquots.request
      wells.aliquots.request.request_metadata
      wells.aliquots.sample.sample_metadata
      wells.requests_as_source
      wells.qc_results
    ].freeze

    VALID_POOL_COUNT_RANGE = Rails.application.config.scrna_config[:valid_pool_count_range]

    # Returns the number of source plates from the purpose configuration.
    #
    # @return [Integer] The number of source plates.
    def max_number_of_source_plates
      @max_number_of_source_plates ||= purpose_config.dig(:creator_class, :args, :max_number_of_source_plates)
    end

    # Returns the WellFilter instance associated with this creator. The filter
    # uses the callback method 'labware_wells' to get the list of wells to
    # filter, which specifies wells in 'passed' state from the source plates.
    # The 'source_wells_for_pooling' method is used to get the filtered wells.
    #
    # @return [WellFilter] The WellFilter instance.
    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    # Returns all passed wells from the source plates in column order.
    #
    # @return [Array<Well>] An array of passed wells.
    def labware_wells
      source_plates.flat_map { |plate| plate.wells_in_columns.select(&:passed?) }
    end

    # Returns all source plates associated with the minimal barcodes.
    #
    # @return [Array<Plate>] An array of source plates.
    def source_plates
      @source_plates ||=
        Sequencescape::Api::V2::Plate.find_all({ barcode: minimal_barcodes }, includes: SOURCE_PLATE_INCLUDES)
    end

    # Returns the source wells for pooling. The wells are filtered using the
    # well_filter.
    #
    # @return [Array<Well>] An array of source wells for pooling.
    def source_wells_for_pooling
      well_filter.filtered.map(&:first) # The first element is the well.
    end

    # Returns a hash mapping each source well to its source plate. The hash
    # contains all source wells independent of the filtering.
    #
    # @return [Hash] A hash where the keys are wells and the values are the plates
    #   that each well belongs to.
    def source_wells_to_plates
      @source_wells_to_plates ||=
        source_plates.each_with_object({}) { |plate, hash| plate.wells.each { |well| hash[well] = plate } }
    end

    # Returns the pools for the destination plate.
    #
    # @return [Array<Pool>] An array of pools.
    def pools
      @pools ||= build_pools
    end

    # Sets the barcodes and minimal_barcodes instance variables. The
    # minimal_barcodes are derived from the barcodes by removing any blank
    # values and stripping whitespace from the remaining values.
    #
    # @param barcodes [Array<String>] An array of barcodes.
    def barcodes=(barcodes)
      @barcodes = barcodes
      @minimal_barcodes = barcodes.compact_blank.map(&:strip)
    end

    # Returns the number of pools that this group of wells should be split between, pulled from request metadata.
    # The number of pools is specified for each group of wells that share the same Study and Project.
    #
    # @param [Array<Well>] group A group of wells from the source plate(s).
    # @return [Integer] The number of pools that they should be split into.
    # @raise [StandardError] If any required attribute is nil.
    def number_of_pools(group)
      group[0]&.aliquots&.first&.request&.request_metadata&.number_of_pools ||
        (raise 'Number of pools is missing or nil')
    end

    # Creates transfer requests from source wells to the destination plate in
    # Sequencescape.
    #
    # @param dest_uuid [String] The UUID of the destination plate.
    # @return [Boolean] Returns true if no exception is raised.
    def transfer_material_from_parent!(dest_uuid)
      dest_plate = Sequencescape::Api::V2::Plate.find_by(uuid: dest_uuid)
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes(dest_plate),
        user_uuid: user_uuid
      )
      determine_if_pools_have_enough_material_for_allowance_band(dest_plate)
      true
    end

    # Generates the attributes for transfer requests from the source wells to the
    # destination plate.
    #
    # @return [Array<Hash>] An array of hashes, each representing the attributes
    #   for a transfer request.
    def transfer_request_attributes(dest_plate)
      well_filter.filtered.filter_map do |source_well, additional_parameters|
        request_hash(source_well, dest_plate, additional_parameters)
      end
    end

    # Generates a hash representing a transfer request from a source well to a
    # destination well. Additional parameters generated by the well filter are
    # merged into the request hash, i.e.'outer_request' and 'submission_id'.
    # tag_depth is added to the aliquot attributes.
    #
    # @param source_well [Sequencescape::Api::V2::Well] The source well.
    # @param dest_plate [Sequencescape::Api::V2::Plate] The destination plate.
    # @param additional_parameters [Hash] Additional parameters to include.
    # @return [Hash] A hash representing a transfer request.
    def request_hash(source_well, dest_plate, additional_parameters)
      dest_location = transfer_hash[source_well][:dest_locn]
      {
        source_asset: source_well.uuid,
        target_asset: dest_plate.well_at_location(dest_location)&.uuid,
        aliquot_attributes: {
          tag_depth: tag_depth_hash[source_well]
        }
      }.merge(additional_parameters)
    end

    # Returns a mapping between each source well to a destination location.
    #
    # @return [Hash] A hash where each key is a source well and each value is a
    #   hash with a single key-value pair: { dest_locn: destination_location }.
    def transfer_hash
      @transfer_hash ||=
        pools
          .each_with_index
          .with_object({}) do |(pool, index), result|
          dest_location = WellHelpers.well_at_column_index(index) # column order, 96 wells
          pool.each { |source_well| result[source_well] = { dest_locn: dest_location } }
        end
    end

    # Returns a hash mapping each source well to its index in its pool plus one.
    # The tag depth is used as an aliquot attribute in the transfer request. It
    # is recorded in Sequencescape to avoid tag clashes.
    #
    # @return [Hash] A hash where keys are wells and values are tag depths.
    def tag_depth_hash
      @tag_depth_hash ||=
        pools
          .each_with_index
          .with_object({}) do |(pool, _pool_index), hash|
          pool.each_with_index { |well, index| hash[well] = (index + 1).to_s }
        end
    end

    # Builds the pools for the destination plate. The wells are first grouped
    # by study and project, then passed along to be allocated to pools.
    #
    # @return [Array<Array<Well>>] An array of well groups distributed across pools.
    def build_pools
      study_project_groups = split_single_group_by_study_and_project(source_wells_for_pooling)

      # allocate_wells_to_pools returns an array of pools
      # We get one of these for every study/project group, and then 'flatten' to get a single array of pools
      built_pools = study_project_groups.flat_map { |group| allocate_wells_to_pools(group, number_of_pools(group)) }

      unless VALID_POOL_COUNT_RANGE.cover?(built_pools.size)
        raise "Invalid requested number of pools: must be between #{VALID_POOL_COUNT_RANGE.min} " \
              "and #{VALID_POOL_COUNT_RANGE.max}. Provided: #{built_pools.size}."
      end

      built_pools
    end

    # Given some wells may have failed, this method determines if we still have enough material to
    # meet the number of runs/cell counts requested in the submission.
    # It iterates over each pool, retrieves the destination well location from the transfer hash,
    # and checks each pool for the allowance band by calling the check_pool_for_allowance_band method
    # in the donor pooling calculator class.
    # That method then writes the number of cells per chip well to the poly_metadata of the pool wells.
    #
    # @return [void]
    def determine_if_pools_have_enough_material_for_allowance_band(dest_plate)
      # a pool is array of v2 wells
      pools.each do |pool|
        # destination location is the same for all wells in the pool, so fetch from first source wells
        dest_well_location = transfer_hash[pool.first][:dest_locn]

        # check this pool for allowance band
        check_pool_for_allowance_band(pool, dest_plate, dest_well_location)
      end
    end
  end
end
