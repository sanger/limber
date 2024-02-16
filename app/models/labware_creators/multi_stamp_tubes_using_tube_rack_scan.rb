# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators/base'

module LabwareCreators
  # Handles the creation of a plate from a number of tubes using an uploaded tube rack scan file.
  #
  # The parents are standard tubes.
  #
  # The user uploads a tube rack scan of the tube barcodes and their positions, and this creator will
  # transfer the tubes into wells on the plate.
  #
  # Inputs:
  # 1) A parent tube - the user has click the add plate button on a specific tube
  # 2) A tube rack scan CSV file - this is a scan of the rack of 2D tube barcodes (the rack is not being tracked)
  #
  # Outputs:
  # 1) A child plate - tubes are stamped into corresponding locations in the plate according to the scan file
  #
  # Validations - Error message to users if any of these are not met:
  # 1) The user must always upload a scan file. Validations of the file must pass and it should parse correctly and
  # contain at least one tube barcode.
  # 2) The tube barcodes must be unique within the file (exclude NO SCAN, NO READ types).
  # 3) The scanned child tube barcode(s) must already exist in the system. List any that do already exist with tube
  # barcode and scan file location.
  # 4) The labware purpose type of each tube must match the one of the expected ones from a list in the plate purpose
  # config. List any that do not match with tube barcode, scan file location and purpose type, and list the expected
  # type(s).
  # 5) The request on the tube must be active, and must match to one of the expected ones from a list in the plate
  # purpose config. This is to check that the tubes are at the appropriate stage of their pipeline to transfer.
  #
  # rubocop:disable Metrics/ClassLength
  class MultiStampTubesUsingTubeRackScan < Base
    include LabwareCreators::CustomPage
    include SupportParent::TubeOnly

    self.page = 'multi_stamp_tubes_using_tube_rack_scan'
    self.attributes += [:file]

    attr_accessor :file

    validates :file, presence: true

    validates_nested :csv_file, if: :file

    # NB. CsvFile checks for duplicated barcodes within the uploaded file (ignores no scan types)
    validate :tubes_must_exist_in_lims, if: :file
    validate :tubes_must_be_of_expected_purpose_type, if: :file
    validate :tubes_must_have_active_requests_of_expected_type, if: :file

    EXPECTED_REQUEST_STATES = %w[pending started].freeze

    def save
      # NB. need the && true!!
      super && upload_tube_rack_file && true
    end

    # Creates child plate, performs transfers.
    #
    # @return [Boolean] true if the child plate was created successfully.
    def create_labware!
      plate_creation =
        api.pooled_plate_creation.create!(parents: parent_tube_uuids, child_purpose: purpose_uuid, user: user_uuid)

      @child = plate_creation.child
      child_v2 = Sequencescape::Api::V2.plate_with_wells(@child.uuid)

      transfer_material_from_parent!(child_v2)

      yield(@child) if block_given?
      true
    end

    # Creates transfer requests for the given transfer request attributes and performs the transfers.
    #
    # @return [void]
    def perform_transfers
      api.transfer_request_collection.create!(user: user_uuid, transfer_requests: transfer_request_attributes)
    end

    # Returns a CsvFile object for the tube rack scan CSV file, or nil if the file doesn't exist.
    def csv_file
      @csv_file ||= CsvFile.new(file) if file
    end

    def file_valid?
      file.present? && csv_file&.valid?
    end

    # Fetches all tubes from the CSV file and stores them in a hash indexed by barcode.
    # This method uses memoization to avoid fetching the tubes more than once.
    def parent_tubes
      @parent_tubes ||=
        csv_file
          .position_details
          .each_with_object({}) do |(_tube_posn, foreign_barcode), tubes|
            search_params = { barcode: foreign_barcode, includes: Sequencescape::Api::V2::Tube::DEFAULT_INCLUDES }

            tubes[foreign_barcode] = Sequencescape::Api::V2::Tube.find_by(**search_params)
          end
    end

    # Validates that all parent tubes in the CSV file exist in the LIMS.
    # Adds an error message for each tube that doesn't exist.
    def tubes_must_exist_in_lims
      return unless file_valid?

      parent_tubes.each do |foreign_barcode, tube_in_db|
        next if tube_in_db.present?

        msg = "Tube barcode #{foreign_barcode} not found in the LIMS"
        errors.add(:base, msg)
      end
    end

    # Validates that all tubes in the parent_tubes hash are of the expected purpose type.
    # If a tube is not of the expected purpose type, an error message is added to the errors object.
    # Tubes that are not found in the database or are of the expected purpose type are skipped.
    # This method is used to ensure that all tubes are of the correct type before starting the transfer.
    def tubes_must_be_of_expected_purpose_type
      return unless file_valid?

      parent_tubes.each do |foreign_barcode, tube_in_db|
        # NB. should be catching missing tubes in previous validation
        next if tube_in_db.blank? || expected_tube_purpose_names.include?(tube_in_db.purpose.name)

        msg =
          "Tube barcode #{foreign_barcode} does not match to one of the expected tube purposes (one of type(s): #{
            expected_tube_purpose_names.join(', ')
          })"
        errors.add(:base, msg)
      end
    end

    # Validates that all tubes in the parent_tubes hash have at least one active request of the expected type.
    # If a tube does not have an active request of the expected type, an error message is added to the errors object.
    # Tubes that are not found in the database or already have an expected active request are skipped.
    # This method is used to ensure that all tubes are ready for processing before starting the transfer.
    def tubes_must_have_active_requests_of_expected_type
      return unless file_valid?

      parent_tubes.each do |foreign_barcode, tube_in_db|
        # NB. should be catching missing tubes in previous validation
        next if tube_in_db.blank? || tube_has_expected_active_request?(tube_in_db)

        msg =
          "Tube barcode #{foreign_barcode} does not have an expected active request (one of type(s): #{
            expected_request_type_keys.join(', ')
          })"
        errors.add(:base, msg)
      end
    end

    def expected_request_type_keys
      purpose_config.dig(:creator_class, :args, :expected_request_type_keys).to_a
    end

    def expected_tube_purpose_names
      purpose_config.dig(:creator_class, :args, :expected_tube_purpose_names).to_a
    end

    def filename_for_tube_rack_scan
      purpose_config.dig(:creator_class, :args, :filename_for_tube_rack_scan)
    end

    private

    # Returns an array of unique UUIDs for all parent tubes.
    # @return [Array<String>] An array of UUIDs.
    def parent_tube_uuids
      parent_tubes.values.pluck(:uuid).uniq
    end

    # Uploads the tube rack scan CSV file to the parent tube using api v1.
    # NB. This is a bit limited as it is only linked to one tube.
    def upload_tube_rack_file
      # TODO: this is failing with URL error despite values for all elements
      # parent.qc_files.create_from_file!(file, filename_for_tube_rack_scan)
      true
    end

    # Returns an array of active requests of the expected type for the given tube.
    # @param tube [Sequencescape::Api::V2::Tube] The tube to get the requests for.
    # @return [Array<Sequencescape::Api::V2::Request>] An array of requests.
    def active_requests_of_expected_type(tube)
      tube.receptacle.requests_as_source.select do |req|
        expected_request_type_keys.include?(req.request_type.key) && EXPECTED_REQUEST_STATES.include?(req.state)
      end
    end

    # Checks if the given tube has any active requests of the expected type.
    # @param tube_in_db [Sequencescape::Api::V2::Tube] The tube to check.
    # @return [Boolean] True if the tube has any active requests of the expected type, false otherwise.
    def tube_has_expected_active_request?(tube_in_db)
      active_requests_of_expected_type(tube_in_db).any?
    end

    # Transfers material from the parent tubes to the given child plate.
    # @param child_plate [Sequencescape::Api::V2::Plate] The plate to transfer material to.
    def transfer_material_from_parent!(child_plate)
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes(child_plate)
      )
    end

    # Returns an array of hashes representing the transfer requests for the given child plate.
    # Each hash includes the UUIDs of the parent tube and child well, and the UUID of the outer request.
    # @param child_plate [Sequencescape::Api::V2::Plate] The plate to get the transfer requests for.
    # @return [Array<Hash>] An array of hashes representing the transfer requests.
    def transfer_request_attributes(child_plate)
      parent_tubes.each_with_object([]) do |(foreign_barcode, parent_tube), tube_transfers|
        tube_transfers <<
          request_hash(
            parent_tube.uuid,
            child_plate
              .wells
              .detect { |child_well| child_well.location == csv_file.location_by_barcode_details[foreign_barcode] }
              &.uuid,
            { outer_request: source_tube_outer_request_uuid(parent_tube) }
          )
      end
    end

    # Generates a transfer request hash for the given source well UUID, target tube UUID, and additional parameters.
    #
    # @param source_tube_uuid [String] The UUID of the source tube.
    # @param target_plate_uuid [String] The UUID of the target plate.
    # @param additional_parameters [Hash] Additional parameters to include in the transfer request hash.
    # @return [Hash] A transfer request hash.
    def request_hash(source_tube_uuid, target_plate_uuid, additional_parameters)
      { 'source_asset' => source_tube_uuid, 'target_asset' => target_plate_uuid }.merge(additional_parameters)
    end

    # Returns the UUID of the first active request of the expected type for the given tube.
    # It assumes that there should be exactly one such request.
    # If no such request is found, it raises an error.
    # This method is used to get the UUID of the outer request when creating a transfer.
    #
    # @param tube [Sequencescape::Api::V2::Tube] The tube to get the request UUID for.
    # @return [String] The UUID of the first active request of the expected type.
    # @raise [RuntimeError] If no active request of the expected type is found for the tube.
    def source_tube_outer_request_uuid(tube)
      requests = active_requests_of_expected_type(tube)

      return requests.first.uuid if requests.first.uuid.present?

      # The validation to check for suitable requests should have caught this
      raise "No active request of expected type found for tube #{tube.human_barcode}"
    end
  end
  # rubocop:enable Metrics/ClassLength
end
