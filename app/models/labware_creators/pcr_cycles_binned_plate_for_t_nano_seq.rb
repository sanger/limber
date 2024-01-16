# frozen_string_literal: true

module LabwareCreators
  # This version of the class is specific to the Targeted NanoSeq pipeline.
  class PcrCyclesBinnedPlateForTNanoSeq < PcrCyclesBinnedPlate
    self.page = 'pcr_cycles_binned_plate_for_t_nano_seq'

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
          'concentration_nm' => details['concentration'],
          'input_amount_available' => details['input_amount_available'],
          'input_amount_desired' => details['input_amount_desired'],
          'sample_volume' => details['sample_volume'],
          'diluent_volume' => details['diluent_volume'],
          'pcr_cycles' => details['pcr_cycles'],
          'hyb_panel' => details['hyb_panel']
        }
        create_request_metadata(request, request_metadata, child_well_location)
      end
    end

    # rubocop:enable Metrics/AbcSize

    # Cycles through a hash of key value pairs and creates a new metadatum for each on the request object.
    # NB. makes assumption that metadata with same name does not already exist i.e. we create not update
    def create_request_metadata(request, request_metadata, child_well_location)
      request_metadata.each do |metadata_key, metadata_value|
        pm_v2 = Sequencescape::Api::V2::PolyMetadatum.new(key: metadata_key, value: metadata_value)

        # NB. this is the only way to set the relationship between the polymetadatum and the request, after
        # the polymetadatum object has been created
        pm_v2.relationships.metadatable = request

        next if pm_v2.save

        raise StandardError,
              "New metadata for request (key: #{metadata[:key]}, value: #{metadata[:value]}) " \
                "did not save for request at child well location #{child_well_location}"
      end
    end

    private

    #
    # Upload the csv file onto the plate via api v1
    #
    def upload_file
      parent_v1.qc_files.create_from_file!(file, 'targeted_nano_seq_customer_file.csv')
    end

    # Create class that will parse and validate the uploaded file
    def csv_file
      @csv_file ||= CsvFileForTNanoSeq.new(file, csv_file_upload_config, parent.human_barcode)
    end
  end
end
