# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate'

  #
  # This version of the csv file is for Targeted NanoSeq.
  #
  class PcrCyclesBinnedPlate::CsvFileForTNanoSeq < PcrCyclesBinnedPlate::CsvFile
    delegate :well_column,
             :concentration_column,
             :sanger_sample_id_column,
             :supplier_sample_name_column,
             :input_amount_available_column,
             :input_amount_desired_column,
             :sample_volume_column,
             :diluent_volume_column,
             :pcr_cycles_column,
             :hyb_panel_column,
             to: :well_details_header_row

    def initialize_variables(file, config, parent_barcode)
      @config = Utility::PcrCyclesForTNanoSeqCsvFileUploadConfig.new(config)
      @parent_barcode = parent_barcode
      @data = CSV.parse(file.read)
      remove_bom
      @parsed = true
    end

    # Returns the contents of the header row for the well detail columns
    def well_details_header_row
      @well_details_header_row ||= WellDetailsHeaderForTNanoSeq.new(@data[2]) if @data[2]
    end

    private

    def transfers
      @transfers ||=
        @data[3..].each_with_index.map do |row_data, index|
          RowForTNanoSeq.new(@config, well_details_header_row, index + 2, row_data)
        end
    end

    # Create the hash of well details from the file upload values
    def generate_well_details_hash
      return {} unless valid?

      fields = %w[
        concentration
        input_amount_available
        input_amount_desired
        sample_volume
        diluent_volume
        pcr_cycles
        hyb_panel
      ]
      transfers.each_with_object({}) do |row, well_details_hash|
        next if row.empty?

        field_to_value = fields.index_with { |field| row.send(field) }

        well_location = row.well
        well_details_hash[well_location] = field_to_value
      end
    end
  end
end
