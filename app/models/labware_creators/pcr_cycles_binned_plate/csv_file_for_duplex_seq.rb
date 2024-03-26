# frozen_string_literal: true

require './lib/nested_validation'
require 'csv'

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate_for_duplex_seq'

  module PcrCyclesBinnedPlate
    #
    # This version of the csv file is for Duplex Seq.
    #
    class CsvFileForDuplexSeq < CsvFileBase
      delegate :submit_for_sequencing_column, :sub_pool_column, :coverage_column, to: :well_details_header_row

      FIELDS_FOR_WELL_DETAILS = %w[diluent_volume pcr_cycles submit_for_sequencing sub_pool coverage sample_volume]
        .freeze

      # Returns the contents of the header row for the well detail columns
      def well_details_header_row
        @well_details_header_row ||= PcrCyclesBinnedPlate::CsvFile::DuplexSeq::WellDetailsHeader.new(@data[2]) if @data[
          2
        ]
      end

      private

      def get_config_details_from_purpose(config)
        Utility::PcrCyclesForDuplexSeqCsvFileUploadConfig.new(config)
      end

      def create_row(index, row_data)
        PcrCyclesBinnedPlate::CsvFile::DuplexSeq::Row.new(@config, well_details_header_row, index + 2, row_data)
      end

      # Gates looking for wells if the file is invalid
      def correctly_formatted?
        @parsed && plate_barcode_header_row.valid? && well_details_header_row.valid?
      end
    end
  end
end
