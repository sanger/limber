# frozen_string_literal: true

module LabwareCreators
  # This version of the class is specific to the Targeted NanoSeq pipeline.
  class PcrCyclesBinnedPlateForTNanoSeq < PcrCyclesBinnedPlateBase
    self.page = 'pcr_cycles_binned_plate_for_t_nano_seq'

    CUSTOMER_FILENAME = 'targeted_nano_seq_customer_file.csv'

    # NB. well filter already catches if there are multiple open requests on the same parent well
    validate :parent_contains_active_requests_of_expected_type
    validate :customer_file_contains_values_for_all_active_requests

    # rubocop:disable Metrics/AbcSize
    def after_transfer!
      # called as part of the 'super' call in the 'save' method
      # retrieve child plate through v2 api, using uuid got through v1 api
      child_v2_plate = Sequencescape::Api::V2.plate_with_custom_includes(CHILD_PLATE_INCLUDES, uuid: child.uuid)

      # cycle through the child wells and for each get the related request and write some metadata
      # to it based on the details in the customer file
      child_wells_by_location = child_v2_plate.wells.index_by(&:location)

      well_details.each do |parent_location, details|
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

    # Cycles through a hash of key value pairs and creates a new metadatum or updates the existing one for
    # each metadata field to be stored against the request object.
    # NB. makes assumption that metadata from previous iterations can be safely overwritten
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

    # to fetch the expected binning request type from the purpose config
    def expected_binning_request_type
      @expected_binning_request_type ||= purpose_config.fetch('expected_binning_request_type')
    end

    # check the parent plate only contains requests of the expected type and no others
    def parent_contains_active_requests_of_expected_type
      # disabled as request_type.key does not work
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

    def customer_file_contains_values_for_all_active_requests
      # parent wells with requests
      parent_wells_with_requests = filtered_wells.map(&:location).sort

      # wells with details in the customer file
      wells_with_details = well_details.keys.sort

      # check the two arrays match (same elements in same order)
      return if parent_wells_with_requests == wells_with_details

      errors.add(
        :base,
        "The uploaded customer file does not contain the same number of rows (#{wells_with_details.count}) " \
          "as there are wells with active requests on the parent plate (#{parent_wells_with_requests.count})"
      )
    end

    # The well filter will be used to identify the parent wells to be taken forward.
    # Filters on request type, library type and state.
    def well_filter
      @well_filter ||= WellFilterAllowingPartials.new(creator: self, request_state: 'pending')
    end

    def find_existing_metadata(metadata_key, request_id)
      Sequencescape::Api::V2::PolyMetadatum.find(key: metadata_key, metadatable_id: request_id).first
    end

    def update_existing_metadata(existing_metadata_v2, metadata_value, metadata_key, child_well_location)
      return if existing_metadata_v2.value == metadata_value

      return if existing_metadata_v2.update(value: metadata_value)

      raise StandardError,
            "Existing metadata for request (key: #{metadata_key}, value: #{metadata_value}) " \
              "could not be updated for request at child well location #{child_well_location}"
    end

    def create_new_metadata(metadata_key, metadata_value, request, child_well_location)
      pm_v2 = Sequencescape::Api::V2::PolyMetadatum.new(key: metadata_key, value: metadata_value)
      pm_v2.relationships.metadatable = request

      return if pm_v2.save

      raise StandardError,
            "New metadata for request (key: #{metadata_key}, value: #{metadata_value}) " \
              "did not save for request at child well location #{child_well_location}"
    end

    # filename for the customer file upload
    def customer_filename
      CUSTOMER_FILENAME
    end

    # Create class that will parse and validate the uploaded file
    def csv_file
      @csv_file ||= PcrCyclesBinnedPlate::CsvFileForTNanoSeq.new(file, csv_file_upload_config, parent.human_barcode)
    end
  end
end
