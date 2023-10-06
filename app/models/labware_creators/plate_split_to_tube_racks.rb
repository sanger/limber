# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators/base'

module LabwareCreators
  # Handles the creation of up to 2 child racks of tubes from a single parent 96-well plate.
  # Intended for use in a PBMC cell extraction pipeline.
  #
  # There will typically be one rack of tubes for 'contingency' and one for 'sequencing' (this rack is
  # optional).
  #
  # The parent plate contains multiple copies of material prepared from the same sample. One well instance
  # of each sample will go into a tube in the 'sequencing' rack (if present), and any remaining copies
  # will go into tubes in the 'contingency' rack.
  #
  # If after the initial preparation the users feel they need more contingency tubes, then they will go
  # back to prepare more material for that sample from an earlier step in the pipeline and create just
  # 'contingency' tubes at this step.
  #
  # Inputs:
  # 1) The parent plate - This plate contains multiple groups of wells containing the same samples e.g.
  #    there may be 3 wells with sample 1, 3 with sample 2, 3 with sample 3 etc. The number of copies of
  #    each sample is not known in advance.
  #    The first of these parent wells will be transferred into a tube in the 'sequencing' rack if it is
  #    present, and any remaining parent wells for the same sample will be transferred into tubes in the
  #    'contingency' rack.
  # 2) Child tube rack scan CSV files - these are scans of racks of 2D tube barcodes from the 'contingency'
  #    and 'sequencing' tube racks, to allow us to know the position and barcode of each available tube.
  #    On the upload screen displays counts of how many tubes are needed (e.g. To perform this transfer you
  #    will either need 20 sequencing and 40 contingency tubes, or 60 contingency tubes.)
  #
  # Validations - Error message to users if any of these are not met:
  # 1) The user must always upload a scan file for the 'contingency' rack tube barcodes, whereas the
  #    'sequencing' rack file is optional.
  # 2) The scanned child tube barcodes must be unique and must not already exist in the system i.e. they are
  #    new unused empty tubes. List any that do already exist with rack type and location.
  # 3) The number of tubes available in the racks must be sufficient for the number of parent wells being
  #    transferred. e.g. if there are 20 distinct samples in the parent and 40 additional copies (60 wells
  #    total), then there must be at least 20 tubes in the first rack and at least 40 in the second rack.
  #    List any racks that do not have enough tubes with totals.
  #
  # rubocop:disable Metrics/ClassLength
  class PlateSplitToTubeRacks < Base
    include SupportParent::PlateOnly

    self.attributes += %i[sequencing_file contingency_file]

    self.page = 'plate_split_to_tube_racks'

    attr_accessor :sequencing_file, :contingency_file

    attr_reader :child_sequencing_tubes, :child_contingency_tubes

    validates_nested :well_filter

    # Don't create the tubes until at least the contingency file has been uploaded
    validates :contingency_file, presence: true

    # N.B. contingency file is required, sequencing file is optional
    validates_nested :sequencing_csv_file, if: :sequencing_file
    validates_nested :contingency_csv_file, if: :contingency_file

    # validate there are sufficient tubes in the racks for the number of parent wells
    validate :sufficient_tubes_in_racks?

    # validate that the tube barcodes do not already exist in the system
    validate :tube_barcodes_are_unique?

    # TODO: check need all this in the includes e.g. metadata
    PARENT_PLATE_INCLUDES = 'wells.aliquots,wells.aliquots.sample,wells.aliquots.sample.sample_metadata'

    def save
      super && upload_tube_rack_files && true
    end

    # v2 api is used to select the parent plate
    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PARENT_PLATE_INCLUDES, uuid: parent_uuid)
    end

    # v1 api is used to upload the tube rack scan files and create the tubes
    def parent_v1
      @parent_v1 ||= api.plate.find(parent_uuid)
    end

    # Sets the filter parameters for the well filter.
    #
    # @param filter_parameters [Hash] The filter parameters to assign.
    # @return [void]
    def filters=(filter_parameters)
      well_filter.assign_attributes(filter_parameters)
    end

    # Returns the unfiltered list of wells of the parent labware.
    #
    # @return [Array<Well>] The wells of the parent labware.
    def labware_wells
      parent.wells
    end

    # Creates child sequencing and contingency tubes, performs transfers.
    #
    # @return [Boolean] true if the child tubes were created successfully.
    def create_labware!
      @child_sequencing_tubes = create_child_sequencing_tubes
      @child_contingency_tubes = create_child_contingency_tubes
      add_child_tube_metadata
      perform_transfers
      true
    end

    # Creates a single child sequencing tube for each parent well containing a unique sample.
    #
    # @return [Array<Tube>] The child sequencing tubes.
    def create_child_sequencing_tubes
      return [] if require_contingency_tubes_only?

      create_tubes(sequencing_tube_purpose_uuid, parent_wells_for_sequencing.length, sequencing_tube_attributes)
    end

    # Creates a child contingency tube for each parent well not already assigned to a sequencing tube.
    #
    # @return [Array<Tube>] The child contingency tubes.
    def create_child_contingency_tubes
      create_tubes(contingency_tube_purpose_uuid, parent_wells_for_contingency.length, contingency_tube_attributes)
    end

    # Creates transfer requests for the given transfer request attributes and performs the transfers.
    #
    # @return [void]
    def perform_transfers
      api.transfer_request_collection.create!(user: user_uuid, transfer_requests: transfer_request_attributes)
    end

    # We will create multiple child tubes, so redirect to the parent plate
    def redirection_target
      parent
    end

    # Display the children tab in the plate view so we see the child tubes listed.
    def anchor
      'children_tab'
    end

    # Returns the number of unique sample UUIDs for the parent wells after applying the current well filter.
    #
    # @return [Integer] The number of unique sample UUIDs.
    def num_parent_unique_samples
      @num_parent_unique_samples ||= parent_uniq_sample_uuids.length
    end

    # Returns the number of parent wells after applying the current well filter.
    #
    # @return [Integer] The number of filtered parent wells.
    def num_parent_wells
      @num_parent_wells ||= well_filter.filtered.length
    end

    # Checks if there are sufficient tubes in the child tube racks for all the parent wells.
    # This depends on the number of unique samples in the parent plate, and the number of parent wells,
    # as well as whether they are using both sequencing tubes and contingency tubes or just contingency.
    #
    # @return [Boolean] `true` if there are sufficient tubes, `false` otherwise.
    def sufficient_tubes_in_racks?
      return if contingency_file.blank?

      if require_contingency_tubes_only?
        num_contingency_tubes >= num_parent_wells
      else
        (num_sequencing_tubes >= num_parent_unique_samples) &&
          (num_contingency_tubes >= (num_parent_wells - num_parent_unique_samples))
      end
    end

    # Validation that the tube barcodes are unique and do not already exist in the system.
    # NB. this checks all the tube barcodes in the uploaded tube rack scan files, not just the
    # ones that will be used.
    #
    # @return [void]
    def tube_barcodes_are_unique?
      check_tube_rack_scan_file(sequencing_csv_file, 'Sequencing') if sequencing_file
      check_tube_rack_scan_file(contingency_csv_file, 'Contingency') if contingency_file
    end

    # Checks if the tube barcodes in the given tube rack file already exist in the LIMS.
    #
    # @param tube_rack_file [CsvFile] The tube rack file to check.
    # @param msg_prefix [String] The prefix to use for error messages.
    # @return [void] Adds errors to the model if the tube barcodes are not unique.
    def check_tube_rack_scan_file(tube_rack_file, msg_prefix)
      tube_rack_file.position_details.each do |tube_posn, tube_details|
        foreign_barcode = tube_details['tube_barcode']
        tube_in_db = Sequencescape::Api::V2::Tube.find_by(barcode: foreign_barcode)
        next if tube_in_db.blank?

        msg = "#{msg_prefix} tube barcode #{foreign_barcode} (at rack position #{tube_posn}) already exists in the LIMS"
        errors.add(:tube_rack_file, msg)
      end
    end

    private

    # Returns a new instance of WellFilter with the current object as the creator.
    # NB. filters failed and cancelled wells by default
    #
    # @return [WellFilter] A new instance of WellFilter.
    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    # Returns the ancestor stock tubes for the parent wells.
    #
    # @return [Array<Sequencescape::Api::V2::Tube>] The ancestor stock tubes.
    def ancestor_stock_tubes
      @ancestor_stock_tubes ||= locate_ancestor_tubes
    end

    # Locates the ancestor stock tubes for the parent wells.
    #
    # @return [Hash{String => Sequencescape::Api::V2::Tube}] A hash of ancestor stock tubes, keyed by sample UUID.
    def locate_ancestor_tubes
      purpose_name = purpose_config[:ancestor_stock_tube_purpose_name]

      ancestor_results = parent.ancestors.where(purpose_name: purpose_name)
      return {} if ancestor_results.blank?

      ancestor_results.each_with_object({}) do |ancestor_result, tube_list|
        tube = Sequencescape::Api::V2::Tube.find_by(uuid: ancestor_result.uuid)
        tube_sample_uuid = tube.aliquots.first.sample.uuid
        tube_list[tube_sample_uuid] = tube if tube_sample_uuid.present?
      end
    end

    # Returns an array of unique sample UUIDs for the parent wells after applying the current well filter.
    #
    # @return [Array<String>] An array of unique sample UUIDs.
    def parent_uniq_sample_uuids
      well_filter.filtered.map { |well, _ignore| well.aliquots.first.sample.uuid }.uniq
    end

    # Returns the number of sequencing tubes in the sequencing CSV file.
    #
    # @return [Integer] The number of sequencing tubes.
    def num_sequencing_tubes
      @num_sequencing_tubes ||= sequencing_csv_file&.position_details&.length || 0
    end

    # Returns the number of contingency tubes in the contingency CSV file.
    #
    # @return [Integer] The number of contingency tubes.
    def num_contingency_tubes
      @num_contingency_tubes ||= contingency_csv_file&.position_details&.length || 0
    end

    # Uploads the sequencing and contingency tube rack scan CSV files to the parent plate using api v1.
    #
    # @return [void]
    def upload_tube_rack_files
      unless require_contingency_tubes_only?
        parent_v1.qc_files.create_from_file!(sequencing_file, 'scrna_core_sequencing_tube_rack_scan.csv')
      end
      parent_v1.qc_files.create_from_file!(contingency_file, 'scrna_core_contingency_tube_rack_scan.csv')
    end

    # Returns a CsvFile object for the sequencing tube rack scan CSV file, or nil if the file doesn't exist.
    #
    # @return [CsvFile, nil] A CsvFile object for the sequencing tube rack scan CSV file, or nil if the file
    # doesn't exist.
    def sequencing_csv_file
      @sequencing_csv_file ||= CsvFile.new(sequencing_file) if sequencing_file
    end

    # Returns a CsvFile object for the contingency tube rack scan CSV file, or nil if the file doesn't exist.
    #
    # @return [CsvFile, nil] A CsvFile object for the contingency tube rack scan CSV file, or nil if the file
    # doesn't exist.
    def contingency_csv_file
      @contingency_csv_file ||= CsvFile.new(contingency_file) if contingency_file
    end

    # Returns true if only contingency tubes are required for the parent plate, false otherwise.
    #
    # @return [Boolean]
    def require_contingency_tubes_only?
      sequencing_file.blank?
    end

    # Returns an array of parent wells that should be transferred to sequencing tubes based on the current well filter.
    #
    # @return [Array<Well>] An array of parent wells.
    def parent_wells_for_sequencing
      @parent_wells_for_sequencing ||= find_parent_wells_for_sequencing
    end

    # Returns an array of parent wells that should be transferred to sequencing tubes based on the current well filter,
    # or an empty array if only contingency tubes are required for the parent plate.
    #
    # @return [Array<Well>] An array of parent wells.
    def find_parent_wells_for_sequencing
      return [] if require_contingency_tubes_only?

      unique_sample_uuids = []
      parent_wells_for_seq = []

      well_filter.filtered.each do |well, _ignore|
        sample_uuid = well.aliquots.first.sample.uuid
        next if sample_uuid.in?(unique_sample_uuids)

        unique_sample_uuids << sample_uuid
        parent_wells_for_seq << well
      end

      parent_wells_for_seq
    end

    # Returns an array of parent wells that should be transferred to contingency tubes based on the current well filter
    # and the wells that will be transferred to sequencing tubes.
    #
    # @return [Array<Well>] An array of parent wells that should be used for contingency tubes.
    def parent_wells_for_contingency
      @parent_wells_for_contingency ||=
        well_filter.filtered.filter_map { |well, _ignore| well unless parent_wells_for_sequencing.include?(well) }
    end

    # Creates a specified number of tubes with the given attributes and returns a hash of the created tubes indexed
    # by name.
    #
    # @param tube_purpose_uuid [String] The UUID of the tube purpose to use for the created tubes.
    # @param number_of_tubes [Integer] The number of tubes to create.
    # @param tube_attributes [Hash] A hash of attributes to use for the created tubes.
    # @return [Hash<String, Tube>] A hash of the created tubes indexed by name.
    def create_tubes(tube_purpose_uuid, number_of_tubes, tube_attributes)
      api
        .specific_tube_creation
        .create!(
          user: user_uuid,
          parent: parent_uuid,
          child_purposes: [tube_purpose_uuid] * number_of_tubes,
          tube_attributes: tube_attributes
        )
        .children
        .index_by(&:name)
    end

    # Returns the name of the sequencing tube purpose based on the current purpose configuration.
    #
    # @return [String] The name of the sequencing tube purpose.
    def sequencing_tube_purpose_name
      @sequencing_tube_purpose_name ||= purpose_config.dig(:creator_class, :args, :child_seq_tube_purpose_name)
    end

    # Returns the prefix to use for the name of a sequencing tube from the purpose config.
    #
    # @return [String] The sequencing tube name prefix.
    def sequencing_tube_name_prefix
      @sequencing_tube_name_prefix ||= purpose_config.dig(:creator_class, :args, :child_seq_tube_name_prefix)
    end

    # Returns the UUID of the sequencing tube purpose based on the current purpose configuration.
    #
    # @return [String] The UUID of the sequencing tube purpose.
    def sequencing_tube_purpose_uuid
      raise "Missing purpose configuration argument 'child_seq_tube_purpose_name'" unless sequencing_tube_purpose_name

      Settings.purpose_uuids[sequencing_tube_purpose_name]
    end

    # Returns the name of the contingency tube purpose based on the current purpose configuration.
    #
    # @return [String] The name of the contingency tube purpose.
    def contingency_tube_purpose_name
      @contingency_tube_purpose_name ||= purpose_config.dig(:creator_class, :args, :child_spare_tube_purpose_name)
    end

    # Returns the prefix to use for the name of a contingency tube from the purpose config.
    #
    # @return [String] The contingency tube name prefix.
    def contingency_tube_name_prefix
      @contingency_tube_name_prefix ||= purpose_config.dig(:creator_class, :args, :child_spare_tube_name_prefix)
    end

    # Returns the UUID of the contingency tube purpose based on the current purpose configuration.
    #
    # @return [String] The UUID of the contingency tube purpose.
    def contingency_tube_purpose_uuid
      unless contingency_tube_purpose_name
        raise "Missing purpose configuration argument 'child_spare_tube_purpose_name'"
      end

      Settings.purpose_uuids[contingency_tube_purpose_name]
    end

    # Returns the human-readable barcode of the ancestor (supplier) source tube for the given sample UUID.
    #
    # @param sample_uuid [String] The UUID of the sample to find the ancestor tube for.
    # @return [String] The human-readable barcode of the ancestor tube.
    # @raise [StandardError] If the ancestor tube cannot be found for the given sample UUID.
    def ancestor_tube_barcode(sample_uuid)
      sample_ancestor_tube = ancestor_stock_tubes[sample_uuid]
      if sample_ancestor_tube.blank?
        raise StandardError, "Failed to identify ancestor (supplier) source tube for sample uuid #{sample_uuid}"
      end

      sample_ancestor_tube.human_barcode
    end

    # Returns a hash of attributes to use for the sequencing tubes.
    #
    # @return [Hash] A hash of attributes to use for the sequencing tubes.
    def sequencing_tube_attributes
      @sequencing_tube_attributes ||=
        generate_tube_attributes('sequencing', sequencing_csv_file, parent_wells_for_sequencing)
    end

    # Returns a hash of attributes to use for the contingency tubes.
    #
    # @return [Hash] A hash of attributes to use for the contingency tubes.
    def contingency_tube_attributes
      @contingency_tube_attributes ||=
        generate_tube_attributes('contingency', contingency_csv_file, parent_wells_for_contingency)
    end

    # Returns the name prefix for child tubes based on the tube type.
    # This method looks up the name prefix in the configuration file based on the tube type.
    # If the name prefix is not found, this method raises an error.
    # @param tube_type [String] The type of tube to generate attributes for ('sequencing' or 'contingency').
    #
    # @return [String] The name prefix for the child tubes.
    # rubocop:disable Metrics/MethodLength
    def tube_name_prefix(tube_type)
      config_arg = ''
      name_prefix =
        if tube_type == 'sequencing'
          config_arg = 'child_seq_tube_name_prefix'
          sequencing_tube_name_prefix
        else
          config_arg = 'child_spare_tube_name_prefix'
          contingency_tube_name_prefix
        end

      raise "Missing purpose configuration argument '#{config_arg}'" unless name_prefix

      name_prefix
    end

    # rubocop:enable Metrics/MethodLength

    # Adds a mapping between a well and a tube name to the appropriate hash based on the tube type.
    # @param tube_type [String] The type of tube to generate attributes for ('sequencing' or 'contingency').
    # @param well [Well] The well to add the mapping for.
    # @param tube_name [String] The name of the tube to add the mapping for.
    #
    # This method adds the mapping to either the `@sequencing_wells_to_tube_names` or to the
    # `@contingency_wells_to_tube_names` hash, depending on the tube type.
    # If the hash does not exist, this method creates it.
    # @return [void]
    def add_to_well_to_tube_hash(tube_type, well, tube_name)
      if tube_type == 'sequencing'
        @sequencing_wells_to_tube_names = {} if @sequencing_wells_to_tube_names.nil?
        @sequencing_wells_to_tube_names[well] = tube_name
      else
        @contingency_wells_to_tube_names = {} if @contingency_wells_to_tube_names.nil?
        @contingency_wells_to_tube_names[well] = tube_name
      end
    end

    # Generates a hash of attributes to use for the tubes based on the
    # current purpose configuration and the available tube positions.
    # Passes the name for each tube.
    # Passes the foreign barcode extracted from the tube rack scan upload for each tube,
    # which on the Sequencescape side sets that barcode as the primary.
    # @param tube_type [String] The type of tube to generate attributes for.
    # @param csv_file [CsvFile] The CSV file containing the tube rack scan data.
    # @param wells [Array<Well>] The parent wells to generate attributes for.
    #
    # @return [Hash] A hash of attributes to use for the contingency tubes.
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def generate_tube_attributes(tube_type, csv_file, wells)
      # fetch the available tube positions (i.e. locations of scanned tubes for which we
      # have the barcodes) e.g. ["A1", "B1", "D1"]
      available_tube_posns = csv_file.position_details.keys

      name_prefix = tube_name_prefix(tube_type)

      wells
        .zip(available_tube_posns)
        .map do |well, tube_posn|
          sample_uuid = well.aliquots.first.sample.uuid

          name_for_details = name_for_details_hash(name_prefix, ancestor_tube_barcode(sample_uuid), tube_posn)

          tube_name = name_for(name_for_details)
          add_to_well_to_tube_hash(tube_type, well, tube_name)

          { name: tube_name, foreign_barcode: csv_file.position_details[tube_posn]['tube_barcode'] }
        end
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # Returns a hash of details to use for generating a tube name based on the given prefix,
    # stock tube barcode, and destination tube position.
    #
    # @param prefix [String] The prefix to use for the tube name.
    # @param stock_tube_bc [String] The barcode of the stock tube.
    # @param dest_tube_posn [String] The position of the destination tube.
    # @return [Hash] A hash of details to use for generating a tube name.
    def name_for_details_hash(prefix, stock_tube_bc, dest_tube_posn)
      { prefix: prefix, stock_tube_bc: stock_tube_bc, dest_tube_posn: dest_tube_posn }
    end

    # Generates a human-readable name for a tube based on the given details hash.
    # Comprises a prefix, the ancestor source (stock) tube barcode and the destination tube position
    #
    # @param details [Hash] A hash of details to use for generating the tube name.
    # @return [String] A human-readable name for the tube. e.g. 'SEQ:NT12345678:A1'
    def name_for(details)
      "#{details[:prefix]}:#{details[:stock_tube_bc]}:#{details[:dest_tube_posn]}"
    end

    # Returns an array of transfer request hashes for the filtered wells and their corresponding child tubes.
    #
    # @return [Array<Hash>] An array of transfer request hashes.
    def transfer_request_attributes
      well_filter.filtered.filter_map do |well, additional_parameters|
        child_tube = find_child_tube(well)

        next unless child_tube

        request_hash(well.uuid, child_tube.uuid, additional_parameters)
      end
    end

    # Finds the child tube corresponding to the given well.
    #
    # @param well [Well] The well to find the child tube for.
    # @return [Tube, nil] The child tube corresponding to the given well, or nil if no child tube was found.
    def find_child_tube(well)
      if require_contingency_tubes_only?
        @child_contingency_tubes[@contingency_wells_to_tube_names[well]]
      else
        @child_sequencing_tubes[@sequencing_wells_to_tube_names[well]] ||
          @child_contingency_tubes[@contingency_wells_to_tube_names[well]]
      end
    end

    # Adds metadata to child tubes using details from the parsed sequencing and contingency CSV files.
    #
    # @return [void]
    def add_child_tube_metadata
      add_sequencing_tube_metadata unless require_contingency_tubes_only?

      add_contingency_tube_metadata
    end

    # Adds tube rack barcode and position metadata to child sequencing tubes.
    #
    # @return [void]
    def add_sequencing_tube_metadata
      child_sequencing_tubes.each do |child_tube_name, child_tube|
        tube_posn = child_tube_name.split(':').last
        add_tube_metadata(child_tube, tube_posn, sequencing_csv_file.position_details[tube_posn])
      end
    end

    # Adds tube rack barcode and position metadata to child contingency tubes.
    #
    # @return [void]
    def add_contingency_tube_metadata
      child_contingency_tubes.each do |child_tube_name, child_tube|
        tube_posn = child_tube_name.split(':').last
        add_tube_metadata(child_tube, tube_posn, contingency_csv_file.position_details[tube_posn])
      end
    end

    # Shared method for adding tube rack barcode and position metadata to child tubes.
    #
    # @param child_tube [Tube] The child tube to add metadata to.
    # @param tube_posn [String] The position of the child tube in the tube rack.
    # @param tube_details [Hash] The tube details hash from the tube rack scan file.
    # @return [void]
    def add_tube_metadata(child_tube, tube_posn, tube_details)
      LabwareMetadata
        .new(api: api, user: user_uuid, barcode: child_tube.barcode.machine)
        .update!(tube_rack_barcode: tube_details['tube_rack_barcode'], tube_rack_position: tube_posn)
    end

    # Generates a transfer request hash for the given source well UUID, target tube UUID, and additional parameters.
    #
    # @param source_well_uuid [String] The UUID of the source well.
    # @param target_tube_uuid [String] The UUID of the target tube.
    # @param additional_parameters [Hash] Additional parameters to include in the transfer request hash.
    # @return [Hash] A transfer request hash.
    def request_hash(source_well_uuid, target_tube_uuid, additional_parameters)
      { 'source_asset' => source_well_uuid, 'target_asset' => target_tube_uuid }.merge(additional_parameters)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
