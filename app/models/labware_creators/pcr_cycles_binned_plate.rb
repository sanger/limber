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
  class PcrCyclesBinnedPlate < StampedPlate
    include LabwareCreators::CustomPage

    MISSING_WELL_DETAIL = 'is missing a row for well %s, all wells with content must have a row in the uploaded file.'
    PENDING_WELL = 'contains at least one pending well %s, the plate and all wells in it should be passed before creating the child plate.'

    self.page = 'pcr_cycles_binned_plate' # TODO: how does this work? new page for uploading file? see custom_pooled_tubes directory in labware_creators
    self.attributes += [:file]

    attr_accessor :file

    # delegate method to return well values to csv file handler class
    delegate :well_details, to: :csv_file

    validates :file, presence: true
    validates_nested :csv_file, if: :file
    validate :wells_have_required_information?

    PARENT_PLATE_INCLUDES =
      'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'

    CHILD_PLATE_INCLUDES =
      'wells.aliquots'

    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PARENT_PLATE_INCLUDES, uuid: parent_uuid)
    end

    def parent_v1
      @parent_v1 ||= api.plate.find(parent_uuid)
    end

    # Configurations from the plate purpose.
    def csv_file_upload_config
      @csv_file_upload_config ||= purpose_config.fetch(:csv_file_upload)
    end

    def dilutions_config
      @dilutions_config ||= purpose_config.fetch(:dilutions)
    end

    def save
      # TODO: need to save well metadata
      # NB. need the && true!!
      super && upload_file && true
    end

    def after_transfer!
      # retrieve child plate through v2 api, using uuid got through v1 api
      child_v2 = Sequencescape::Api::V2.plate_with_custom_includes(CHILD_PLATE_INCLUDES, uuid: child.uuid)

      fields_to_update = %w[pcr_cycles submit_for_sequencing sub_pool coverage]

      child_wells_by_location = {}
      child_v2.wells.each { |well| child_wells_by_location[well.location] = well }

      well_details.each do |parent_location, details|
        child_position = transfer_hash[parent_location]['dest_locn']
        child_well = child_wells_by_location[child_position]

        options = fields_to_update.each_with_object({}) { |field, obj| obj[field] = details[field] }

        child_well.update_attributes(options)
      end
    end

    def wells_have_required_information?
      filtered_wells.each do |well|
        next if well.aliquots.empty?

        errors.add(:csv_file, format(MISSING_WELL_DETAIL, well.location)) unless well_details.include? well.location
        errors.add(:csv_file, format(PENDING_WELL, well.location)) if well.pending?
      end
    end

    def dilutions_calculator
      @dilutions_calculator ||= Utility::PcrCyclesBinningCalculator.new(well_details)
    end

    private

    # Returns the parent wells selected to be taken forward.
    def filtered_wells
      well_filter.filtered.each_with_object([]) do |well_filter_details, wells|
        wells << well_filter_details[0]
      end
    end

    #
    # Upload the csv file onto the plate via api v1
    #
    def upload_file
      parent_v1.qc_files.create_from_file!(file, 'duplex_seq_customer_file.csv')
    end

    # Create class that will parse and validate the uploaded file
    def csv_file
      @csv_file ||= CsvFile.new(file, csv_file_upload_config, parent.human_barcode)
    end

    # Override this method in sub-class if required.
    def request_hash(source_well, child_plate, additional_parameters)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect do |child_well|
          child_well.location == transfer_hash[source_well.location]['dest_locn']
        end&.uuid,
        'volume' => transfer_hash[source_well.location]['volume'].to_s
      }.merge(additional_parameters)
    end

    # Uses the calculator to generate the hash of transfers to be performed on the parent plate
    def transfer_hash
      @transfer_hash ||= dilutions_calculator.compute_well_transfers(parent)
    end
  end
end
