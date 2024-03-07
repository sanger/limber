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
  #
  # The number of pools is determined by a lookup table based on sample count.
  # Tag depth index is added to aliquot attributes to avoid tag clashes.
  class DonorPoolingPlate < Base
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly

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
      wells.aliquots.sample.sample_metadata
      wells.requests_as_source
    ].freeze

    # TODO: Remove this default once a new CSV file is provided.
    # The default number of pools to be created if the count is not found in
    # the lookup table. For scRNA Donor Pooling, until a new CSV file is
    # provided, a copy of Cardinal pooling config is used, which goes up to 96
    # samples. From 97 to 160 samples, the number of pools to create is 16.
    DEFAULT_NUMBER_OF_POOLS = 16

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

    # Reurns all passed wells from the source plates in column order.
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

    # Returns the number of pools based on the sample count from the lookup
    # table. If the count is not found in the table, the default number of
    # pools is returned.
    #
    # @return [Integer] The number of pools.
    def number_of_pools
      Rails.application.config.scrna_core_donor_pooling_config.fetch(
        source_wells_for_pooling.count,
        DEFAULT_NUMBER_OF_POOLS
      )
    end

    # Creates transfer requests from source wells to the destination plate in
    # Sequencescape.
    #
    # @param dest_uuid [String] The UUID of the destination plate.
    # @return [Boolean] Returns true if no exception is raised.
    def transfer_material_from_parent!(dest_uuid)
      dest_plate = Sequencescape::Api::V2::Plate.find_by(uuid: dest_uuid)
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes(dest_plate)
      )
      true
    end

    # Generates the attributes for transfer requests from the source wells to the
    # destination plate.
    #
    # @param dest_plate [Sequencescape::Api::V2::Plate] The destination plate.
    # @return [Array<Hash>] An array of hashes, each representing the attributes
    #   for a transfer request.
    def transfer_request_attributes(dest_plate)
      well_filter.filtered.filter_map do |source_well, additional_parameters|
        request_hash(source_well, dest_plate, additional_parameters)
      end
    end

    # Returns the well from a plate that matches the specified location. If no
    # well is found at the specified location, nil is returned. Used by the
    # 'request_hash' method to find the destination well.
    #
    # @param plate [Sequencescape::Api::V2::Plate] The destination plate.
    # @param well_location [String] The location to match.
    # @return [Sequencescape::Api::V2::Well, nil] The well at the specified location,
    #   or nil if no well is found.
    def get_well_for_plate_location(plate, well_location)
      plate.wells.detect { |well| well.location == well_location }
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
        'source_asset' => source_well.uuid,
        'target_asset' => get_well_for_plate_location(dest_plate, dest_location)&.uuid,
        :aliquot_attributes => {
          'tag_depth' => tag_depth(source_well)
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

    # Returns the tag depth for the given source well. The tag depth is the
    # position of the well in its pool. It is used used as an aliquot attribute
    # in the transfer request. It is recorded in Sequencescape to avoid tag
    # clashes.
    #
    # @param source_well [Well] The source well for which to retrieve the tag depth.
    # @return [String] The tag depth as a string, or nil if the well is not in a pool.
    def tag_depth(source_well)
      pools.each do |pool|
        return (pool.index(source_well) + 1).to_s if pool.index(source_well)
        # index + 1 incase of 0th index
      end
    end

    # Builds the pools for the destination plate. The wells are first grouped
    # by study and project, then split by donor_ids, and finally distributed
    # across pools.
    #
    # @return [Array<Array<Well>>] An array of well groups distributed across pools.
    def build_pools
      groups = split_single_group_by_study_and_project(source_wells_for_pooling)
      groups = split_groups_by_unique_donor_ids(groups)
      distribute_groups_across_pools(groups, number_of_pools)
    end
  end
end
