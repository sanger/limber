# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate_for_t_nano_seq'

  module PcrCyclesBinnedPlate
    #
    # This version of the csv file is for Targeted NanoSeq.
    #
    class CsvFileForTNanoSeq < CsvFileBase
      delegate :hyb_panel_column, to: :well_details_header_row

      FIELDS_FOR_WELL_DETAILS = %w[
        concentration
        input_amount_available
        input_amount_desired
        sample_volume
        diluent_volume
        pcr_cycles
        hyb_panel
      ].freeze

      # Returns the contents of the header row for the well detail columns
      def well_details_header_row
        @well_details_header_row ||= PcrCyclesBinnedPlate::CsvFile::TNanoSeq::WellDetailsHeader.new(@data[2]) if @data[
          2
        ]
      end

      private

      def get_config_details_from_purpose(config)
        Utility::PcrCyclesForTNanoSeqCsvFileUploadConfig.new(config)
      end

      def create_row(index, row_data)
        PcrCyclesBinnedPlate::CsvFile::TNanoSeq::Row.new(@config, well_details_header_row, index + 2, row_data)
      end
    end
  end
end
