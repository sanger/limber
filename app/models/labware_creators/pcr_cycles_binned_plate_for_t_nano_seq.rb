# frozen_string_literal: true

module LabwareCreators
  # This version of the class is specific to the Targeted NanoSeq pipeline.
  class PcrCyclesBinnedPlateForTNanoSeq < PcrCyclesBinnedPlateBase
    self.page = 'pcr_cycles_binned_plate_for_t_nano_seq'

    CUSTOMER_FILENAME = 'targeted_nano_seq_customer_file.csv'

    # rubocop:disable Metrics/AbcSize
    def after_transfer!
      # called as part of the 'super' call in the 'save' method
      # retrieve child plate through v2 api, using uuid got through v1 api
      child_v2_plate = Sequencescape::Api::V2.plate_with_custom_includes(CHILD_PLATE_INCLUDES, uuid: child.uuid)

      # update fields on each well with various metadata
      child_wells_by_location = child_v2_plate.wells.index_by(&:location)

      well_details.each do |parent_location, details|
        child_well_location = transfer_hash[parent_location]['dest_locn']
        child_well = child_wells_by_location[child_well_location]

        # NB. this seems to return an array of requests via the api but a single request in tests
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
