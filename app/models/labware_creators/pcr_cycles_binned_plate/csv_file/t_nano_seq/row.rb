# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate/csv_file_for_t_nano_seq'

  module PcrCyclesBinnedPlate::CsvFile
    #
    # This version of the row is for the Targeted NanoSeq pipeline.
    #
    class TNanoSeq::Row < RowBase
      include ActiveModel::Validations

      HYB_PANEL_MISSING = 'is empty, in %s'

      attr_reader :hyb_panel

      validate :hyb_panel_is_present?

      delegate :hyb_panel_column, to: :header

      def initialize_pipeline_specific_columns
        @hyb_panel = @row_data[hyb_panel_column]&.strip
      end

      # Checks whether the Hyb Panel column is filled in
      def hyb_panel_is_present?
        return true if empty?

        # TODO: can we validate the hyb panel value? Does not appear to be tracked in LIMS.
        result = hyb_panel.present?
        unless result
          msg = format(HYB_PANEL_MISSING, to_s)
          errors.add('hyb_panel', msg)
        end
        result
      end
    end
  end
end
