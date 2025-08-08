# frozen_string_literal: true

module LabwareCreators
  # This version of the class is specific to the Targeted NanoSeq pipeline.
  class PcrCyclesBinnedPlateForTNanoSeq < PcrCyclesBinnedPlateBase
    self.page = 'pcr_cycles_binned_plate_for_t_nano_seq'

    CUSTOMER_FILENAME = 'targeted_nano_seq_customer_file.csv'

    # NB. well filter already catches if there are multiple open requests on the same parent well
    validate :parent_contains_active_requests_of_expected_type
    validate :customer_file_contains_values_for_all_active_requests

    # This method is called after the transfer of wells from the parent plate to the child plate.
    # It retrieves the child plate through the v2 API, then iterates over the child wells.
    # For each child well, it gets the related request and writes some metadata to it based on the details in the
    # customer file.
    # The metadata includes the original plate barcode, original well ID, concentration, input amount available,
    # input amount desired, sample volume, diluent volume, PCR cycles, and hybridization panel.
    # If a request cannot be identified for a child well, it raises a StandardError.
    #
    # @raise [StandardError] if a request cannot be identified for a child well
    # rubocop:disable Metrics/AbcSize
    def after_transfer!
      # re-request the child plate to include additional metadata
      child_plate = Sequencescape::Api::V2.plate_with_custom_includes(CHILD_PLATE_INCLUDES, uuid: child.uuid)

      # cycle through the child wells and for each get the related request and write some metadata
      # to it based on the details in the customer file
      child_wells_by_location = child_plate.wells.index_by(&:location)

      filtered_well_details_without_wells_flagged_to_be_ignored.each do |parent_location, details|
        child_well_location = transfer_hash[parent_location]['dest_locn']
        child_well = child_wells_by_location[child_well_location]

        # NB. this seems to return an array of requests via the api but a single request in tests
        # Because this is the child plate, the active request should be in the aliquot.
        # i.e. if parent is LTN AL Lib and has submission for ISC Prep on it, then the parent well will have the active
        # request in the well.requests_as_source, whereas the child will have it in the aliquot.request
        request = Array(child_well.aliquots.first.request).first

        if request.blank?
          raise StandardError, "Unable to identify request for child plate well at location #{child_well_location}"
        end

        # create hash containing the key value pairs we want to store as metadata on the request
        request_metadata = {
          'original_plate_barcode' => parent.human_barcode,
          'original_well_id' => parent_location,
          'concentration_nm' => details['concentration'].to_s,
          'input_amount_available' => details['input_amount_available'].to_s,
          'input_amount_desired' => details['input_amount_desired'].to_s,
          'sample_volume' => details['sample_volume'].to_s,
          'diluent_volume' => details['diluent_volume'].to_s,
          'pcr_cycles' => details['pcr_cycles'].to_s,
          'hyb_panel' => details['hyb_panel']
        }
        create_or_update_request_metadata(request, request_metadata, child_well_location)
      end
    end

    # rubocop:enable Metrics/AbcSize

    # Iterates over the provided request metadata and for each key-value pair, it either updates the existing metadata
    # if it's present or creates a new metadata if it's not present.
    #
    # @param request [Sequencescape::Api::V2::Request] the request associated with the metadata
    # @param request_metadata [Hash] the metadata to create or update, where the keys are metadata keys and the values
    # are metadata values
    # @param child_well_location [String] the location of the child well associated with the request
    def create_or_update_request_metadata(request, request_metadata, child_well_location)
      request_metadata.each do |metadata_key, metadata_value|
        existing_metadata_v2 = find_existing_metadata(metadata_key, request.id)

        if existing_metadata_v2.present?
          update_existing_metadata(existing_metadata_v2, metadata_value, metadata_key, child_well_location)
        else
          create_new_metadata(metadata_key, metadata_value, request, child_well_location)
        end
      end
    end

    private

    # Returns the expected binning request type as specified in the purpose configuration.
    # The result is memoized, so subsequent calls to this method will return the same value.
    #
    # @return [String] the expected binning request type
    def expected_binning_request_type
      @expected_binning_request_type ||= purpose_config.fetch('expected_binning_request_type')
    end

    # Checks if the parent plate contains only active requests of the expected type.
    # If the parent plate contains requests of unexpected types, it adds an error message to the base attribute of the
    # errors object.
    # The error message includes the expected request type and the unexpected types found.
    def parent_contains_active_requests_of_expected_type
      # had to disable rubocop here as the suggested request_type.key does not work
      # rubocop:disable Performance/MapMethodChain
      request_type_keys = filtered_wells.flat_map { |well| well.active_requests.map(&:request_type).map(&:key) }.uniq

      # rubocop:enable Performance/MapMethodChain

      return if request_type_keys.one? && request_type_keys.include?(expected_binning_request_type)

      request_types_present = request_type_keys.join(', ')

      errors.add(
        :base,
        "Parent plate should only contain active requests of type (#{expected_binning_request_type}), " \
        "found unexpected types (#{request_types_present})"
      )
    end

    # Filters out well details where the 'pcr_cycles' value is '1', as these are flagged to be ignored.
    # The result is a hash where the keys are well locations and the values are hashes of well details.
    #
    # @return [Hash] the filtered well details
    def filtered_well_details_without_wells_flagged_to_be_ignored
      well_details.reject { |_key, hash| hash['pcr_cycles'].to_s == '1' }
    end

    # Returns a sorted array of well locations from the filtered well details, excluding wells that are flagged to
    # be ignored.
    # The result is memoized, so subsequent calls to this method will return the same array.
    #
    # @return [Array<String>] the sorted array of well locations
    def well_locns_from_filtered_well_details
      @well_locns_from_filtered_well_details ||= filtered_well_details_without_wells_flagged_to_be_ignored.keys.sort
    end

    # Returns the list of parent wells with submission requests ie. wells submitted to progress
    # The result is memoized, so subsequent calls to this method will return the same array.
    #
    # @return [Array<String>] the sorted array of well locations
    def parent_wells_with_requests
      @parent_wells_with_requests ||= filtered_wells.map(&:location).sort
    end

    # Checks if the number of wells in the customer file matches the number of wells submitted for work on the
    # parent plate.
    # If the numbers don't match, it adds an error message to the base attribute of the errors object.
    # The error message includes the number of valid rows in the customer file, the number of wells submitted
    # for work, and a list of wells that are present in the submission but missing in the file, or vice versa.
    def customer_file_contains_values_for_all_active_requests
      return if parent_wells_with_requests == well_locns_from_filtered_well_details

      msg_list = generate_msg_list_for_file_not_matching_submission

      errors.add(
        :base,
        'The uploaded Customer file does not contain the same number of valid rows ' \
        "(#{well_locns_from_filtered_well_details.count}) " \
        "as there are wells submitted for work on the parent plate (#{parent_wells_with_requests.count}). " \
        "Please check the Customer file vs the Submission for missing or extra rows. #{msg_list.join(', ')}"
      )
    end

    # Generates a list of messages for each well location that is present in the submission but missing in the file,
    # or present in the file but missing in the submission.
    # Each message includes the well location, whether it's present in the file, and whether it's present in the
    # submission.
    #
    # @return [Array<String>] the list of messages
    def generate_msg_list_for_file_not_matching_submission
      parent_wells = parent.wells.map(&:location)
      parent_wells.filter_map do |well_locn|
        well_in_submission = parent_wells_with_requests.include?(well_locn)
        valid_well_row_in_file = well_locns_from_filtered_well_details.include?(well_locn)

        next if well_in_submission == valid_well_row_in_file

        "Well #{well_locn} - File: #{valid_well_row_in_file ? 'present' : 'missing'}, " \
          "Submission: #{well_in_submission ? 'present' : 'missing'}"
      end
    end

    # The well filter will be used to identify the parent wells to be taken forward.
    # Filters on request type, library type and state.
    # Returns a new instance of WellFilterAllowingPartials.
    # The instance is created with the creator set to self and the request_state set to 'pending'.
    # The instance is memoized, so subsequent calls to this method will return the same instance.
    #
    # @return [WellFilterAllowingPartials] the WellFilterAllowingPartials instance
    def well_filter
      @well_filter ||= WellFilterAllowingPartials.new(creator: self, request_state: 'pending')
    end

    # Finds and returns the first existing metadata that matches the provided key and request ID.
    # If no matching metadata is found, it returns nil.
    #
    # @param metadata_key [String] the key of the metadata to find
    # @param request_id [Integer] the ID of the request associated with the metadata
    # @return [Sequencescape::Api::V2::PolyMetadatum, nil] the found metadata or nil if no matching metadata is found
    def find_existing_metadata(metadata_key, request_id)
      Sequencescape::Api::V2::PolyMetadatum.find(key: metadata_key, metadatable_id: request_id).first
    end

    # Updates the value of an existing metadata if it's different from the provided value.
    # If the metadata fails to update, it raises a StandardError with a descriptive message.
    #
    # @param existing_metadata_v2 [Sequencescape::Api::V2::Metadatum] the existing metadata to update
    # @param metadata_value [String] the new value for the metadata
    # @param metadata_key [String] the key of the metadata
    # @param child_well_location [String] the location of the child well associated with the request
    # @raise [StandardError] if the existing metadata fails to update
    def update_existing_metadata(existing_metadata_v2, metadata_value, metadata_key, child_well_location)
      return if existing_metadata_v2.value == metadata_value

      return if existing_metadata_v2.update(value: metadata_value)

      raise StandardError,
            "Existing metadata for request (key: #{metadata_key}, value: #{metadata_value}) " \
            "could not be updated for request at child well location #{child_well_location}"
    end

    # Creates a new metadata for a given request with the provided key and value.
    # If the metadata fails to save, it raises a StandardError with a descriptive message.
    #
    # @param metadata_key [String] the key for the new metadata
    # @param metadata_value [String] the value for the new metadata
    # @param request [Sequencescape::Api::V2::Request] the request to which the metadata is associated
    # @param child_well_location [String] the location of the child well associated with the request
    # @raise [StandardError] if the new metadata fails to save
    def create_new_metadata(metadata_key, metadata_value, request, child_well_location)
      pm_v2 = Sequencescape::Api::V2::PolyMetadatum.new(key: metadata_key, value: metadata_value)
      pm_v2.relationships.metadatable = request

      return if pm_v2.save

      raise StandardError,
            "New metadata for request (key: #{metadata_key}, value: #{metadata_value}) " \
            "did not save for request at child well location #{child_well_location}"
    end

    # Filename for the customer file upload (inherits from the base class - cannot reference the constant directly)
    def customer_filename
      CUSTOMER_FILENAME
    end

    # Returns a new instance of PcrCyclesBinnedPlate::CsvFileForTNanoSeq.
    # The instance is created with the file, csv_file_upload_config, and the human_barcode of the parent.
    # The instance is memoized, so subsequent calls to this method will return the same instance.
    #
    # @return [PcrCyclesBinnedPlate::CsvFileForTNanoSeq] the CsvFileForTNanoSeq instance
    def csv_file
      @csv_file ||= PcrCyclesBinnedPlate::CsvFileForTNanoSeq.new(file, csv_file_upload_config, parent.human_barcode)
    end
  end
end
