# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate_base'

  #
  # Takes the user uploaded csv file, validates the content and extracts the well information.
  # This file will be downloaded from Limber based on the quantification results, then sent out
  # to and filled in by the customer. It describes how to dilute and bin the samples together
  # in the child dilution plate.
  # This is the abstract version of this labware creator, extend from this class
  #
  class PcrCyclesBinnedPlate::CsvFileBase < CommonFileHandling::CsvFileBase
    validates :plate_barcode_header_row, presence: true
    validates_nested :plate_barcode_header_row
    validates :well_details_header_row, presence: true
    validates_nested :well_details_header_row
    validates_nested :transfers, if: :correctly_formatted?

    delegate :well_column,
             :concentration_column,
             :sanger_sample_id_column,
             :supplier_sample_name_column,
             :input_amount_available_column,
             :input_amount_desired_column,
             :sample_volume_column,
             :diluent_volume_column,
             :pcr_cycles_column,
             to: :well_details_header_row

    # implement on subclasses
    FIELDS_FOR_WELL_DETAILS = [].freeze

    #
    # Passing in the file to be parsed, the configuration that holds validation range thresholds, and
    # the parent plate barcode for validation that we are processing the correct file.
    def initialize(file, config, parent_barcode)
      super(file)
      @config = get_config_details_from_purpose(config)
      @parent_barcode = parent_barcode
    end

    def reset_variables
      @config = nil
      @parent_barcode = nil
      @filename = nil
      @data = []
      @parsed = false
    end

    #
    # Extracts well details from the uploaded csv file
    #
    # @return [Hash] eg. { 'A1' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0,
    # 'pcr_cycles' => 14, 'submit_for_sequencing' => 'Y', 'sub_pool' => 1, 'coverage' => 15 }, etc. }
    #
    def well_details
      @well_details ||= generate_well_details_hash
    end

    def plate_barcode_header_row
      # data[0] here is the first row in the uploaded file, and should contain the plate barcode
      return unless @data[0]

      @plate_barcode_header_row ||=
        PcrCyclesBinnedPlate::CsvFile::PlateBarcodeHeader.new(@parent_barcode, @data[0])
    end

    # Returns the contents of the header row for the well detail columns
    def well_details_header_row
      raise '#well_details_header_row must be implemented on subclasses'
    end

    private

    def get_config_details_from_purpose(_config)
      raise '#get_config_details_from_purpose must be implemented on subclasses'
    end

    def transfers
      # sample row data starts on third row of file, 1st row is plate barcode header row, second blank
      @transfers ||= @data[3..].each_with_index.map { |row_data, index| create_row(index, row_data) }
    end

    def create_row(_index, _row_data)
      raise '#create_row must be implemented on subclasses'
    end

    # Gates looking for wells if the file is invalid
    def correctly_formatted?
      @parsed && plate_barcode_header_row.valid? && well_details_header_row.valid?
    end

    # Create the hash of well details from the file upload values
    def generate_well_details_hash
      return {} unless valid?

      fields = self.class::FIELDS_FOR_WELL_DETAILS

      transfers.each_with_object({}) do |row, well_details_hash|
        next if row.empty?

        field_to_value = fields.index_with { |field| row.send(field) }

        well_location = row.well
        well_details_hash[well_location] = field_to_value
      end
    end
  end
end
