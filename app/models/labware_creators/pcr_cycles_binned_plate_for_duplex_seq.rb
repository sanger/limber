# frozen_string_literal: true

module LabwareCreators
  # Handles the generation of a plate with wells binned according to the number of
  # PCR cycles that has been determined by the customer.
  # Uploads a file supplied by the customer that has a row per each well and
  # includes Sample Volume, Diluent Volume, PCR Cycles, Sub-Pool and Coverage columns.
  # Uses the PCR Cycles column to determine the binning arrangement of the wells,
  # and the Sample Volume and Diluent Volume columns in the well transfers.
  # Sub-Pool and Coverage need to be stored for a later step downstream in the pipeline,
  # at the point where custom pooling is performed.
  # Wells in the bins are applied to the destination by column order.
  # If there is enough space on the destination plate each new bin will start in a new
  # column. Otherwise bins will run consecutively without gaps.
  #
  #
  # Source Plate                  Dest Plate
  # +--+--+--~                    +--+--+--~
  # |A1| pcr_cycles = 12 (bin 2)  |B1|A1|C1|
  # +--+--+--~                    +--+--+--~
  # |B1| pcr_cycles = 15 (bin 1)  |D1|E1|  |
  # +--+--+--~  +                 +--+--+--~
  # |C1| pcr_cycles = 10 (bin 3)  |  |G1|  |
  # +--+--+--~                    +--+--+--~
  # |D1| pcr_cycles = 15 (bin 1)  |  |  |  |
  # +--+--+--~                    +--+--+--~
  # |E1| pcr_cycles = 12 (bin 2)  |  |  |  |
  # +--+--+--~                    +--+--+--~
  # |G1| pcr_cycles = 12 (bin 2)  |  |  |  |
  class PcrCyclesBinnedPlateForDuplexSeq < PcrCyclesBinnedPlateBase
    self.page = 'pcr_cycles_binned_plate'

    CUSTOMER_FILENAME = 'duplex_seq_customer_file.csv'

    def after_transfer!
      # re-request the child plate to include additional metadata
      child_plate = Sequencescape::Api::V2.plate_with_custom_includes(CHILD_PLATE_INCLUDES, uuid: child.uuid)

      # update fields on each well with various metadata
      fields_to_update = %w[diluent_volume pcr_cycles submit_for_sequencing sub_pool coverage]

      child_wells_by_location = child_plate.wells.index_by(&:location)

      well_details.each do |parent_location, details|
        child_position = transfer_hash[parent_location]['dest_locn']
        child_well = child_wells_by_location[child_position]

        update_well_with_metadata(child_well, details, fields_to_update)
      end
    end

    def update_well_with_metadata(well, metadata, fields_to_update)
      options = fields_to_update.index_with { |field| metadata[field] }
      well.update(options)
    end

    private

    # filename for the customer file upload
    def customer_filename
      CUSTOMER_FILENAME
    end

    # Create class that will parse and validate the uploaded file
    def csv_file
      @csv_file ||= PcrCyclesBinnedPlate::CsvFileForDuplexSeq.new(file, csv_file_upload_config, parent.human_barcode)
    end
  end
end
