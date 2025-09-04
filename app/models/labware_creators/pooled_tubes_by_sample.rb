# frozen_string_literal: true

require_dependency 'labware_creators/base'

module LabwareCreators
  ##
  # Pools from a plate into tubes, grouping together wells that contain the same sample
  # NB. Currently this is specific to the Cardinal usage of FluidX tubes
  ##
  class PooledTubesBySample < PooledTubesBase # rubocop:todo Metrics/ClassLength
    include CreatableFrom::PlateOnly
    include LabwareCreators::CustomPage

    self.page = 'tube_creation/pooled_tubes_by_sample'
    self.attributes += [:file]

    attr_accessor :file

    # delegate method to return well values to csv file handler class
    delegate :well_details, to: :csv_file

    validates :file, presence: true # Don't create the tubes until the file has been uploaded
    validates_nested :csv_file, if: :file # Don't create the tubes until the file has been validated
    validate :must_have_enough_tubes_for_pools # Don't create the tubes if there aren't enough available for our needs

    PARENT_PLATE_INCLUDES = 'wells.aliquots,wells.aliquots.sample,wells.aliquots.sample.sample_metadata'

    def save
      super && upload_file && true
    end

    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PARENT_PLATE_INCLUDES, uuid: parent_uuid)
    end

    # TODO: QUESTIONS:
    #
    # Should we pre-filter wells, based on whether they have been failed, or based on what request they have?
    #   -> Should check this general strategy with team, as labware creators are inconsistent.
    #
    # Are these pool identifiers recorded in the db? SS transfer_request.rb mentions 'the pool_id attribute on well'...?
    #
    # Have we made this class so cardinal-specific (e.g. lookup of ancestor vac tubes) that it cannot be re-used?

    def create_child_stock_tubes
      Sequencescape::Api::V2::SpecificTubeCreation
        .create!(
          child_purpose_uuids: [purpose_uuid] * pool_uuids.length,
          parent_uuids: [parent_uuid],
          tube_attributes: tube_attributes,
          user_uuid: user_uuid
        )
        .children
        .index_by(&:name)
    end

    def name_for_details(pool_identifier)
      {
        source_tube_barcode: pools_with_extra_details[pool_identifier][:source_tube_barcode],
        destination_tube_posn: pools_with_extra_details[pool_identifier][:destination_tube_posn]
      }
    end

    def transfer_request_attributes
      pools.each_with_object([]) do |(pool_identifier, pool), transfer_requests|
        pool.each do |location|
          transfer_requests << request_hash(
            well_locations.fetch(location).uuid,
            child_stock_tubes.fetch(name_for(name_for_details(pool_identifier))).uuid,
            pool_identifier
          )
        end
      end
    end

    def pools
      @pools ||= determine_pools
    end

    private

    #
    # Create the tube attributes to send for the tubes creation in Sequencescape.
    # Passes the name for each tube.
    # Passes the foreign barcode extracted from the tube rack scan upload for each tube,
    # which on the Sequencescape side sets that barcode as the primary.
    #
    # returns [Array of hashes] e.g.
    # [
    #   {
    #     name: NT11111111:A1,
    #     foreign_barcode: FD11111111
    #   },
    #   {
    #     name: NT22222222:B1,
    #     foreign_barcode: FD22222222
    #   },
    #   etc.
    # ]
    # Assumption: pools are already in column order (by first sample instance appearance in
    # the source plate)
    #
    def tube_attributes
      # fetch the available tube positions (i.e. locations of scanned tubes for which we
      # have the barcodes) e.g. ["A1", "B1", "D1"]
      available_tube_positions = csv_file.position_details.keys

      pools_with_extra_details.values.each_with_index.map do |pool_details, pool_index|
        tube_posn = available_tube_positions[pool_index]

        # set tube position in pools_with_extra_details for use later in transfer requests
        pool_details[:destination_tube_posn] = tube_posn

        name_for_details = { source_tube_barcode: pool_details[:source_tube_barcode], destination_tube_posn: tube_posn }
        { name: name_for(name_for_details), foreign_barcode: csv_file.position_details[tube_posn]['tube_barcode'] }
      end
    end

    #
    # Generates a name for the destination tube.
    # Comprises the ancestor source (stock) tube barcode and the destination tube position
    # return [String] e.g. 'NT12345678:A1'
    #
    def name_for(name_for_details)
      "#{name_for_details[:source_tube_barcode]}:#{name_for_details[:destination_tube_posn]}"
    end

    #
    # Upload the CSV file for the plate.
    #
    def upload_file
      Sequencescape::Api::V2::QcFile.create_for_labware!(
        contents: file.read,
        filename: 'tube_rack_scan_file.csv',
        labware: parent
      )
    end

    #
    # Create class that will parse and validate the uploaded file
    #
    def csv_file
      @csv_file ||= CommonFileHandling::CsvFileForTubeRack.new(file) if file
    end

    #
    # Validate that we have identified enough destination tube barcodes from the rack scan csv for
    # the number of pools that we have to transfer.
    # @return [void]
    #
    def must_have_enough_tubes_for_pools
      return if pools.blank?
      return if csv_file.blank?

      num_pools = pools.count
      num_tubes = csv_file.position_details.count

      return unless num_pools > num_tubes

      # TODO: test this
      errors.add(
        :csv_file,
        "contains #{num_tubes} tubes, whereas we need #{num_pools} to match the number of unique samples"
      )
    end

    def pools_with_extra_details
      @pools_with_extra_details ||= extract_pools_with_extra_details
    end

    def ancestor_stock_tubes
      @ancestor_stock_tubes ||= locate_ancestor_tubes
    end

    #
    # Identify the originally supplied ancestor source tubes from their purpose name
    # and create a hash with sample uuid as the key
    # @return [Hash] e.g.
    # {
    #   <sample 1 uuid>: <tube 1>,
    #   <sample 2 uuid>: <tube 2>,
    #   etc.
    # }
    def locate_ancestor_tubes
      purpose_name = purpose_config[:ancestor_stock_tube_purpose_name]

      ancestor_results = parent.ancestors.where(purpose_name:)
      return {} if ancestor_results.blank?

      ancestor_results.each_with_object({}) do |ancestor_result, tube_list|
        tube = Sequencescape::Api::V2::Tube.find_by(uuid: ancestor_result.uuid)
        tube_sample_uuid = tube.aliquots.first.sample.uuid
        tube_list[tube_sample_uuid] = tube if tube_sample_uuid.present?
      end
    end

    # get the original supplier (ancestor) tube barcode (if not already set on this pool)
    def add_sample_ancestor_tube_barcode(extra_details, sample_uuid)
      sample_ancestor_tube_barcode = ancestor_stock_tubes[sample_uuid]
      if sample_ancestor_tube_barcode.blank?
        raise StandardError, "Failed to identify ancestor (supplier) source tube for sample uuid #{sample_uuid}"
      end

      extra_details[sample_uuid][:source_tube_barcode] = sample_ancestor_tube_barcode.labware_barcode.human
    end

    #
    # Builds pools_with_extra_details hash, based on which wells contain the same sample.
    # Uses the sample uuid as the key for the pool.
    #
    # @return [Hash of Hashes] e.g.
    # {
    #   "a1aa0101-16e1-11ec-80e2-acde48001121" = {
    #     'locations' => ["A1", "B1"],
    #     'source_tube_barcode' => 'NT12345678'
    #   }
    # }
    # where 'A1' and 'B1' are the coordinates of the source wells to go into that pool
    #
    # rubocop:disable Metrics/AbcSize
    def extract_pools_with_extra_details
      extra_details = Hash.new { |hash, pool_name| hash[pool_name] = { locations: [] } }

      parent.wells_in_columns.each do |well|
        next if well.empty?

        sample_uuid = well.aliquots.first.sample.uuid

        # the same sample may be present in more than one well
        extra_details[sample_uuid][:locations] << well.location
        next if extra_details[sample_uuid].key?(:source_tube_barcode)

        add_sample_ancestor_tube_barcode(extra_details, sample_uuid)
      end
      extra_details
    end

    # rubocop:enable Metrics/AbcSize

    #
    # Builds pools hash, based on which wells contain the same sample.
    # Uses the sample uuid as the key for the pool.
    #
    # @return [Hash] e.g. { "a1aa0101-16e1-11ec-80e2-acde48001121" => ["A1", "B1"] }
    # where 'A1' and 'B1' are the coordinates of the source wells to go into that pool
    #
    def determine_pools
      pools = Hash.new { |hash, pool_name| hash[pool_name] = [] }
      pools_with_extra_details.each_key do |sample_uuid|
        pools[sample_uuid] = pools_with_extra_details[sample_uuid][:locations]
      end
      pools
    end

    def request_hash(source, target, submission)
      { source_asset: source, target_asset: target, submission: submission, merge_equivalent_aliquots: true }
    end
  end
end
