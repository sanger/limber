# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate/csv_file_for_duplex_seq'

  module PcrCyclesBinnedPlate::CsvFile::DuplexSeq
    #
    # Class WellDetailsHeader provides a simple wrapper for handling and validating
    # the plate barcode header row from the customer csv file
    #
    class WellDetailsHeader < PcrCyclesBinnedPlate::CsvFile::WellDetailsHeaderBase
      # Return the index of the respective column.
      attr_reader :submit_for_sequencing_column, :sub_pool_column, :coverage_column

      SUBMIT_FOR_SEQUENCING_COLUMN = 'Submit for sequencing (Y/N)?'
      SUB_POOL_COLUMN = 'Sub-Pool'
      COVERAGE_COLUMN = 'Coverage'

      validates :submit_for_sequencing_column,
                presence: {
                  message: ->(object, _data) { "could not be found in: '#{object}'" }
                }
      validates :sub_pool_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }
      validates :coverage_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }

      private

      def initialize_pipeline_specific_columns
        @submit_for_sequencing_column = index_of_header(SUBMIT_FOR_SEQUENCING_COLUMN)
        @sub_pool_column = index_of_header(SUB_POOL_COLUMN)
        @coverage_column = index_of_header(COVERAGE_COLUMN)
      end
    end
  end
end
