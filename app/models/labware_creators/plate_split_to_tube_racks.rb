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
  # 3) The number of tubes available in the racks must be correct for the number of parent wells being
  #    transferred. e.g. if there are 20 distinct samples in the parent and 40 additional copies (60 wells
  #    total), then there must be 20 tubes in the first rack and 40 in the second rack.
  #
  # rubocop:disable Metrics/ClassLength
  class PlateSplitToTubeRacks < Base
    include LabwareCreators::CustomPage
    include CreatableFrom::PlateOnly

    self.page = 'tube_rack_creation/plate_split_to_tube_racks'
    self.attributes += %i[sequencing_file contingency_file]

    attr_accessor :sequencing_file, :contingency_file
    attr_reader :tube_rack_attributes, :child_tube_racks

    validates_nested :well_filter

    # Don't create the tubes until at least the sequencing file has been uploaded
    validate :validate_file_presence

    # N.B. sequencing file is required, contingency file is optional
    validates_nested :sequencing_csv_file, if: :sequencing_file
    validates_nested :contingency_csv_file, if: :contingency_file

    # validations for duplications between the two tube rack files
    validate :check_tube_rack_barcodes_differ_between_files
    validate :check_tube_barcodes_differ_between_files

    validate :check_decode_failure_in_tube_rack_files

    # validate there are sufficient tubes in the racks for the number of parent wells
    validate :must_have_correct_number_of_tubes_in_rack_files, if: :contingency_file

    # validate that the tube barcodes do not already exist in the system
    validate :tube_barcodes_are_unique?

    PARENT_PLATE_INCLUDES =
      'wells.aliquots,wells.aliquots.sample,wells.downstream_tubes,wells.downstream_tubes.custom_metadatum_collection'
    SEQ_TUBE_RACK_NAME = 'SEQ Tube Rack'
    SPR_TUBE_RACK_NAME = 'SPR Tube Rack'
    DEFAULT_TUBE_RACK_SIZE = '96'

    # Text used to indicate a barcode decode failure in tube rack scan files (applies to both sequencing
    # and contingency racks).
    # This value appears in the barcode field when the scanner is unable to read a tube barcode.
    # If present, the system will block progress and display an informative error to the user.
    DECODE_FAILURE_TEXT = 'DECODE FAILURE'

    def validate_file_presence
      if sequencing_file.blank?
        errors.add(:base, "Sequencing file can't be blank")
      elsif contingency_file.present? && sequencing_file.blank?
        errors.add(:base, 'If contingency_file is present, sequencing_file must also be present.')
      end
    end

    def save
      # NB. need the && true!!
      super && upload_tube_rack_files && true
    end

    # The parent plate via the V2 API.
    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PARENT_PLATE_INCLUDES, uuid: parent_uuid)
    end

    # Returns the list of wells of the parent labware.
    # In column order (A1, B1, C1 etc.)
    # Used in WellFilter.
    #
    # @return [Array<Well>] The wells of the parent labware.
    def labware_wells
      parent.wells_in_columns
    end

    # Creates child sequencing and contingency tubes, performs transfers.
    #
    # @return [Boolean] true if the child tubes were created successfully.
    def create_labware!
      @child_tube_racks = create_child_tubes_and_racks

      if child_tube_racks.blank?
        errors.add(:base, 'Failed to create child tube racks and tubes, nothing returned from API creation call')
        return false
      end

      perform_transfers
      true
    end

    #   @example [
    #   {
    #     :tube_rack_name=>"Seq Tube Rack",
    #     :tube_rack_barcode=>"TR00000001",
    #     :tube_rack_purpose_uuid=>"0ab4c9cc-4dad-11ef-8ca3-82c61098d1a1",
    #     :racked_tubes=>[
    #       {
    #         :tube_barcode=>"SQ45303801",
    #         :tube_name=>"SEQ:NT749R:A1",
    #         :tube_purpose_uuid=>"0ab4c9cc-4dad-11ef-8ca3-82c61098d1a1",
    #         :tube_position=>"A1",
    #         :parent_uuids=>["bd49e7f8-80a1-11ef-bab6-82c61098d1a0"]
    #       },
    #       etc... more tubes
    #     ]
    #   },
    #   etc... second rack for contingency tubes
    def generate_tube_rack_attributes
      @tube_rack_attributes = []
      tube_rack_attributes << generate_sequencing_tube_rack_attributes(tube_rack_attributes)
      return if require_sequencing_tubes_only?

      tube_rack_attributes << generate_contingency_tube_rack_attributes(tube_rack_attributes)
    end

    def create_child_tubes_and_racks
      # create an array of tube rack details, including the tubes
      generate_tube_rack_attributes

      Sequencescape::Api::V2::SpecificTubeRackCreation
        .create!(parent_uuids: [parent_uuid], tube_rack_attributes: tube_rack_attributes, user_uuid: user_uuid)
        .children # returns list of api v2 TubeRacks
        .index_by(&:name)
    end

    # Creates transfer requests for the given transfer request attributes and performs the transfers.
    #
    # @return [void]
    def perform_transfers
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes,
        user_uuid: user_uuid
      )
    end

    # We redirect to the sequencing tube rack that we have just created.
    def redirection_target
      child_tube_racks[SEQ_TUBE_RACK_NAME]
    end

    # Display the relatives tab on the child tube rack page.
    def anchor
      'relatives_tab'
    end

    # Returns a CsvFile object for the sequencing tube rack scan CSV file, or nil if the file doesn't exist.
    #
    # @return [CsvFile, nil] A CsvFile object for the sequencing tube rack scan CSV file, or nil if the file
    # doesn't exist.
    def sequencing_csv_file
      return unless sequencing_file

      @sequencing_csv_file ||=
        CommonFileHandling::CsvFileForTubeRackWithRackBarcode.new(sequencing_file)
    end

    # Returns a CsvFile object for the contingency tube rack scan CSV file, or nil if the file doesn't exist.
    #
    # @return [CsvFile, nil] A CsvFile object for the contingency tube rack scan CSV file, or nil if the file
    # doesn't exist.
    def contingency_csv_file
      return unless contingency_file

      @contingency_csv_file ||=
        CommonFileHandling::CsvFileForTubeRackWithRackBarcode.new(contingency_file)
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

    # Validation to compare the tube rack barcodes in the two files to check for duplication
    #
    # Sets errors if the tube rack barcodes are the same
    def check_tube_rack_barcodes_differ_between_files
      return unless contingency_file_valid? && sequencing_file_valid?

      return unless same_tube_rack_barcode?

      errors.add(
        :contingency_csv_file,
        'The tube rack barcodes within the contingency and sequencing files must be different'
      )
    end

    # Checks if the sequencing tube rack barcode is the same as the contingency tube rack barcode.
    #
    # @return [Boolean] true if the barcodes are the same, false otherwise
    def same_tube_rack_barcode?
      sequencing_tube_rack_barcode == contingency_tube_rack_barcode
    end

    # Validation to compare the tube barcodes in the two files to check for duplication
    #
    # Sets errors if the tube rack barcodes are the same
    def check_tube_barcodes_differ_between_files
      return unless sequencing_file_valid? && contingency_file_valid?

      seq_barcodes = extract_barcodes(sequencing_csv_file)
      cont_barcodes = extract_barcodes(contingency_csv_file)

      duplicate_barcodes = seq_barcodes & cont_barcodes
      return if duplicate_barcodes.empty?

      errors.add(
        :contingency_csv_file,
        "Tube barcodes are duplicated across contingency and sequencing files (#{duplicate_barcodes.join(', ')})"
      )
    end

    # Validation that checks for 'DECODE FAILURE' in the uploaded tube rack scan files.
    #
    # This validation inspects both the sequencing and contingency tube rack scan CSV files (if present).
    # If any barcode in either file is exactly 'DECODE FAILURE', it adds an error to the corresponding file attribute
    # ('Sequencing tube rack scan file' or 'Contingency tube rack scan file').
    #
    # The error message is informative, explaining that 'DECODE FAILURE' means the scanner could not decode a barcode
    # in one or more positions, and instructs the user to check and re-scan the affected tubes.
    #
    # Example error message:
    #   "Sequencing csv file contains 'DECODE FAILURE'. This means the scanner could not decode a barcode in one or
    #   more positions. Please check your file and re-scan the affected tubes."
    #
    # This prevents the user from progressing if a decode failure is detected in the uploaded files.

    def check_decode_failure_in_tube_rack_files
      [sequencing_csv_file, contingency_csv_file].each_with_index do |csv_file, idx|
        next if csv_file.blank?

        barcodes = extract_barcodes(csv_file)
        next unless barcodes.any?('DECODE FAILURE')

        file_type = idx.zero? ? 'Sequencing tube rack scan file' : 'Contingency tube rack scan file'
        errors.add(
          file_type,
          "contains 'DECODE FAILURE'. This means the scanner could not decode a barcode in one or more positions. " \
          'Please check your file and re-scan the affected tubes.'
        )
      end
    end

    def extract_barcodes(file)
      file.position_details.values.pluck('tube_barcode')
    end

    # Validation that checks if there are the correct number of tubes in the child tube racks for all
    # the parent wells.
    # This depends on the number of unique samples in the parent plate, and the number of parent wells,
    # as well as whether they are using both sequencing tubes and contingency tubes or just contingency.
    #
    # Sets errors if there are insufficient or too many tubes.
    def must_have_correct_number_of_tubes_in_rack_files
      return unless files_valid?

      unless require_sequencing_tubes_only?
        add_error_if_wrong_number_of_tubes(
          :contingency_csv_file,
          num_contingency_tubes,
          num_parent_wells - num_parent_unique_samples
        )
      end
      add_error_if_wrong_number_of_tubes(:sequencing_csv_file, num_sequencing_tubes, num_parent_unique_samples)
    end

    # Checks the files passed their validations
    def files_valid?
      return sequencing_file_valid? if require_sequencing_tubes_only?

      contingency_file_valid? && sequencing_file_valid?
    end

    def sequencing_file_valid?
      sequencing_file.present? && sequencing_csv_file&.valid?
    end

    def contingency_file_valid?
      contingency_file.present? && contingency_csv_file&.valid?
    end

    # Adds an error when there are insufficient or too many tubes in the given file
    def add_error_if_wrong_number_of_tubes(file, num_tubes, required_tubes)
      # msg if too many tubes
      errors.add(file, 'contains more tubes than needed') if num_tubes > required_tubes

      # msg if not enough tubes
      errors.add(file, 'contains insufficient tubes') unless num_tubes >= required_tubes
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

    def stock_labware_purpose_name
      @stock_labware_purpose_name ||= purpose_config.dig(:creator_class, :args, :ancestor_stock_tube_purpose_name)
    end

    # Locates the ancestor stock tubes for the parent wells.
    #
    # @return [Hash{String => Sequencescape::Api::V2::Tube}] A hash of ancestor stock tubes, keyed by sample UUID.
    def locate_ancestor_tubes
      ancestor_results = parent.ancestors.where(purpose_name: stock_labware_purpose_name)

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

    # Retrieves the tube rack barcode from the sequencing CSV file.
    #
    # @return [String] the tube rack barcode extracted from the sequencing CSV file
    # @raise [KeyError, NoMethodError] if the expected keys or methods are not present in the sequencing CSV file
    def sequencing_tube_rack_barcode
      @sequencing_tube_rack_barcode ||= extract_tube_rack_barcode(sequencing_csv_file)
    end

    # Retrieves the tube rack barcode from the contingency CSV file.
    #
    # @return [String] the tube rack barcode extracted from the contingency CSV file
    # @raise [KeyError, NoMethodError] if the expected keys or methods are not present in the contingency CSV file
    def contingency_tube_rack_barcode
      @contingency_tube_rack_barcode ||= extract_tube_rack_barcode(contingency_csv_file)
    end

    # Extracts the tube rack barcode from the given file.
    # This method assumes that the file has a `position_details` attribute, which is a hash.
    #
    # @param file [Object] the file object containing position details
    # @return [String] the tube rack barcode extracted from the file
    # @raise [KeyError, NoMethodError] if the expected keys or methods are not present in the file object
    def extract_tube_rack_barcode(file)
      file.position_details.values.first['tube_rack_barcode']
    end

    # Uploads the sequencing and contingency tube rack scan CSV files for the parent plate.
    #
    # @return [Void]
    def upload_tube_rack_files
      unless require_sequencing_tubes_only?
        Sequencescape::Api::V2::QcFile.create_for_labware!(
          contents: contingency_file.read,
          filename: 'scrna_core_contingency_tube_rack_scan.csv',
          labware: parent
        )
      end

      Sequencescape::Api::V2::QcFile.create_for_labware!(
        contents: sequencing_file.read,
        filename: 'scrna_core_sequencing_tube_rack_scan.csv',
        labware: parent
      )
    end

    # Returns true if only contingency tubes are required for the parent plate, false otherwise.
    #
    # @return [Boolean]
    def require_sequencing_tubes_only?
      contingency_file.blank?
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
      unique_sample_uuids = []
      parent_wells_for_seq = []

      well_filter.filtered.each do |(well, _ignore)|
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

    # Returns the name of the sequencing tube rack purpose based on the current purpose configuration.
    #
    # @return [String] The name of the sequencing tube rack purpose.
    def sequencing_tube_rack_purpose_name
      @sequencing_tube_rack_purpose_name ||=
        purpose_config.dig(:creator_class, :args, :child_seq_tube_rack_purpose_name)
    end

    # Returns the UUID of the sequencing tube rack purpose based on the current purpose configuration.
    #
    # @return [Sequencescape::Api::V2::TubeRackPurpose] The sequencing tube rack purpose.
    def sequencing_tube_rack_purpose
      unless sequencing_tube_rack_purpose_name
        raise "Missing purpose configuration argument 'child_seq_tube_rack_purpose_name'"
      end

      Sequencescape::Api::V2::TubeRackPurpose.find(name: sequencing_tube_rack_purpose_name).first
    end

    def sequencing_tube_rack_purpose_uuid
      @sequencing_tube_rack_purpose_uuid ||= sequencing_tube_rack_purpose.uuid
    end

    # Returns the name of the contingency tube rack purpose based on the current purpose configuration.
    #
    # @return [String] The name of the contingency tube rack purpose.
    def contingency_tube_rack_purpose_name
      @contingency_tube_rack_purpose_name ||=
        purpose_config.dig(:creator_class, :args, :child_spare_tube_rack_purpose_name)
    end

    # Returns the contingency tuberack purpose based on the current purpose configuration.
    #
    # @return [Sequencescape::Api::V2::TubeRackPurpose] The contingency tuberack purpose.
    def contingency_tube_rack_purpose
      unless contingency_tube_rack_purpose_name
        raise "Missing purpose configuration argument 'child_spare_tube_rack_purpose_name'"
      end

      Sequencescape::Api::V2::TubeRackPurpose.find(name: contingency_tube_rack_purpose_name).first
    end

    # Returns the UUID of the contingency tube rack purpose.
    #
    # @return [String] The UUID of the contingency tube rack purpose.
    def contingency_tube_rack_purpose_uuid
      @contingency_tube_rack_purpose_uuid ||= contingency_tube_rack_purpose.uuid
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
    def generate_sequencing_tube_rack_attributes(_tube_rack_attributes)
      {
        tube_rack_name: SEQ_TUBE_RACK_NAME,
        tube_rack_barcode: sequencing_tube_rack_barcode,
        tube_rack_purpose_uuid: sequencing_tube_rack_purpose_uuid,
        racked_tubes:
          generate_tube_attributes(
            'sequencing',
            sequencing_csv_file,
            sequencing_tube_purpose_uuid,
            parent_wells_for_sequencing
          )
      }
    end

    # Returns a hash of attributes to use for the contingency tubes.
    #
    # @return [Hash] A hash of attributes to use for the contingency tubes.
    def generate_contingency_tube_rack_attributes(_tube_rack_attributes)
      {
        tube_rack_name: SPR_TUBE_RACK_NAME,
        tube_rack_barcode: contingency_tube_rack_barcode,
        tube_rack_purpose_uuid: contingency_tube_rack_purpose_uuid,
        racked_tubes:
          generate_tube_attributes(
            'contingency',
            contingency_csv_file,
            contingency_tube_purpose_uuid,
            parent_wells_for_contingency
          )
      }
    end

    # Returns the name prefix for child tubes based on the tube type.
    # This method looks up the name prefix in the configuration file based on the tube type.
    # If the name prefix is not found, this method raises an error.
    # @param tube_type [String] The type of tube to generate attributes for ('sequencing' or 'contingency').
    #
    # @return [String] The name prefix for the child tubes.
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

    # Generates a hash of attributes to use for the tubes based on the
    # current purpose configuration and the available tube positions.
    # @param tube_type [String] The type of tube to generate attributes for.
    # @param csv_file [CsvFile] The CSV file containing the tube rack scan data.
    # @param tube_purpose_uuid [String] The UUID of the tube purpose to use for the tubes.
    # @param wells [Array<Well>] The parent wells to generate attributes for.
    #
    # @return [Array<Hash>] A array of hashes of tube attributes.
    # rubocop:disable Metrics/AbcSize
    def generate_tube_attributes(tube_type, csv_file, tube_purpose_uuid, wells)
      # fetch the available tube positions (i.e. locations of scanned tubes for which we
      # have the barcodes) e.g. ["A1", "B1", "D1"]
      available_tube_posns = csv_file.position_details.keys

      name_prefix = tube_name_prefix(tube_type)

      wells
        .zip(available_tube_posns)
        .map do |well, tube_posn|
          # NB. assumption of 1 sample per well, but only used for name generation
          sample_uuid = well.aliquots.first.sample.uuid

          # generate a human-readable name for the tube
          name_for_details = name_for_details_hash(name_prefix, ancestor_tube_barcode(sample_uuid), tube_posn)
          tube_name = name_for(name_for_details)

          {
            tube_barcode: csv_file.position_details[tube_posn]['tube_barcode'],
            tube_name: tube_name,
            tube_purpose_uuid: tube_purpose_uuid,
            tube_position: tube_posn,
            parent_uuids: [well.uuid]
          }
        end
    end

    # rubocop:enable Metrics/AbcSize

    # Returns a hash of details to use for generating a tube name based on the given prefix,
    # stock tube barcode, and destination tube position.
    #
    # @param prefix [String] The prefix to use for the tube name.
    # @param stock_tube_bc [String] The barcode of the stock tube.
    # @param dest_tube_posn [String] The position of the destination tube.
    # @return [Hash] A hash of details to use for generating a tube name.
    def name_for_details_hash(prefix, stock_tube_bc, dest_tube_posn)
      { prefix:, stock_tube_bc:, dest_tube_posn: }
    end

    # Generates a human-readable name for a tube based on the given details hash.
    # Comprises a prefix, the ancestor source (stock) tube barcode and the destination tube position
    #
    # @param details [Hash] A hash of details to use for generating the tube name.
    # @return [String] A human-readable name for the tube. e.g. 'SEQ:NT12345678:A1'
    def name_for(details)
      "#{details[:prefix]}:#{details[:stock_tube_bc]}:#{details[:dest_tube_posn]}"
    end

    # Fetches the tube barcodes for a given well UUID.
    #
    # This method iterates over the tube rack attributes and selects the racked tubes
    # whose parent UUIDs include the specified well UUID. It then extracts the tube
    # barcodes from the selected racked tubes.
    #
    # @param well_uuid [String] The UUID of the well for which to fetch tube barcodes.
    # @return [Array<String>] An array of tube barcodes associated with the specified well UUID.
    #
    def fetch_tube_barcodes_for_well(well_uuid)
      tube_rack_attributes.flat_map do |tube_rack|
        tube_rack[:racked_tubes]
          .select { |racked_tube| racked_tube[:parent_uuids].include?(well_uuid) }
          .pluck(:tube_barcode)
      end
    end

    # Generates a hash mapping tube barcodes to their corresponding UUIDs.
    #
    # This method iterates over the child tube racks and their racked tubes,
    # extracting the barcode and UUID of each tube. It then stores these values
    # in a hash, where the keys are the human-readable barcodes and the values
    # are the corresponding UUIDs.
    #
    # @return [Hash{String => String}] A hash mapping tube barcodes to their UUIDs.
    #
    # Example:
    #   {
    #     "ABC123" => "uuid-1234-5678-9012",
    #     "DEF456" => "uuid-2345-6789-0123"
    #   }
    #
    def generate_tube_uuids_by_barcode
      child_tube_racks.each_with_object({}) do |(_tube_rack_name, tube_rack), tube_uuids_by_barcode|
        tube_rack.racked_tubes.each do |racked_tube|
          tube = racked_tube.tube
          tube_barcode = tube.barcode.human
          tube_uuid = tube.uuid

          # store barcode to uuid mapping
          tube_uuids_by_barcode[tube_barcode] = tube_uuid
        end
      end
    end

    # Returns a hash mapping tube barcodes to their corresponding UUIDs.
    def tube_uuids_by_barcode
      @tube_uuids_by_barcode ||= generate_tube_uuids_by_barcode
    end

    # Generates transfer request attributes for each well and its child tubes.
    #
    # This method iterates over the filtered wells and generates transfer request
    # attributes for each well and its associated child tubes. It raises an error
    # if it is unable to identify the child tube barcodes or the newly created
    # child tube UUIDs for any well.
    #
    # @return [Array<Hash>] An array of hashes representing the transfer request attributes.
    #
    # @raise [RuntimeError] If unable to identify the child tube barcodes for a well.
    # @raise [RuntimeError] If unable to identify the newly created child tube UUID for a well.
    #
    # Example:
    #   [
    #     {
    #       well_uuid: "uuid-1234-5678-9012",
    #       tube_uuid: "uuid-2345-6789-0123",
    #       additional_parameters: { ... }
    #     },
    #     ...
    #   ]
    #
    def transfer_request_attributes
      well_filter
        .filtered
        .each_with_object([]) do |(well, additional_parameters), transfer_requests|
          well_uuid = well.uuid
          tube_barcodes_for_well = fetch_tube_barcodes_for_well(well_uuid)

          validate_tube_barcodes_for_well!(tube_barcodes_for_well, well)

          tube_barcodes_for_well.each do |tube_barcode_for_well|
            tube_uuid = fetch_tube_uuid_for_barcode(tube_barcode_for_well, well)
            transfer_requests << request_hash(well_uuid, tube_uuid, additional_parameters)
          end
        end
    end

    # Validates the presence of tube barcodes for a given well.
    #
    # This method checks if the tube_barcodes_for_well array is blank and raises
    # an error if it is. It ensures that there are child tube barcodes for the
    # specified well.
    #
    # @param tube_barcodes_for_well [Array<String>] An array of tube barcodes for the well.
    # @param well [Object] The well object for which to validate tube barcodes.
    # @raise [RuntimeError] If the tube_barcodes_for_well array is blank.
    #
    def validate_tube_barcodes_for_well!(tube_barcodes_for_well, well)
      return if tube_barcodes_for_well.present?

      raise "Unable to identify the child tube barcodes for parent well '#{well.position[:name]}'"
    end

    # Fetches the tube UUID for a given tube barcode.
    #
    # This method retrieves the tube UUID for the specified tube barcode from the
    # tube_uuids_by_barcode hash. It raises an error if the tube UUID is blank.
    #
    # @param tube_barcode_for_well [String] The barcode of the tube for which to fetch the UUID.
    # @param well [Object] The well object associated with the tube barcode.
    # @return [String] The UUID of the tube.
    # @raise [RuntimeError] If the tube UUID is blank.
    #
    # Example:
    #   tube_uuid = fetch_tube_uuid_for_barcode("ABC123", well)
    #   # => "uuid-2345-6789-0123"
    #
    def fetch_tube_uuid_for_barcode(tube_barcode_for_well, well)
      tube_uuid = tube_uuids_by_barcode[tube_barcode_for_well]
      if tube_uuid.blank?
        raise "Unable to identify the newly created child tube for parent well '#{well.position[:name]}'"
      end

      tube_uuid
    end

    # Generates a transfer request hash for the given source well UUID, target tube UUID, and additional parameters.
    #
    # @param source_well_uuid [String] The UUID of the source well.
    # @param target_tube_uuid [String] The UUID of the target tube.
    # @param additional_parameters [Hash] Additional parameters to include in the transfer request hash.
    # @return [Hash] A transfer request hash.
    def request_hash(source_well_uuid, target_tube_uuid, additional_parameters)
      { source_asset: source_well_uuid, target_asset: target_tube_uuid }.merge(additional_parameters)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
