# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate/csv_file_for_t_nano_seq'

  module PcrCyclesBinnedPlate::CsvFile
    #
    # Class WellDetailsHeader provides a simple wrapper for handling and validating
    # the plate barcode header row from the customer csv file
    # This version is for the Targeted NanoSeq pipeline.
    #
    class TNanoSeq::WellDetailsHeader < WellDetailsHeaderBase
      include ActiveModel::Validations

      # Return the index of the respective column.
      attr_reader :hyb_panel_column

      HYB_PANEL_COLUMN = 'Hyb Panel'
      NOT_FOUND = 'could not be found in: '

      validates :hyb_panel_column, presence: { message: ->(object, _data) { "#{NOT_FOUND}'#{object}'" } }

      private

      def initialize_pipeline_specific_columns
        @hyb_panel_column = index_of_header(HYB_PANEL_COLUMN)
      end
    end
  end
end
