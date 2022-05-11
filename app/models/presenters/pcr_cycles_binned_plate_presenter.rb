# frozen_string_literal: true

module Presenters
  #
  # The PcrCyclesBinnedPlatePresenter is used for plates that have had
  # pcr cycle binning applied. It shows a view of the plate with colours
  # and keys indicating the various bins.
  #
  class PcrCyclesBinnedPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    CURRENT_PLATE_INCLUDES = 'wells.aliquots,wells.qc_results'

    self.summary_partial = 'labware/plates/binned_summary'
    self.aliquot_partial = 'binned_aliquot'

    validates_with Validators::ActiveRequestValidator

    def current_plate
      @current_plate ||= Sequencescape::Api::V2.plate_with_custom_includes(CURRENT_PLATE_INCLUDES, uuid: labware.uuid)
    end

    def dilutions_calculator
      @dilutions_calculator ||= Utility::PcrCyclesBinningCalculator.new(well_details)
    end

    def bins_key
      dilutions_calculator.presenter_bins_key
    end

    def bin_details
      @bin_details ||= dilutions_calculator.compute_presenter_bin_details
    end

    private

    def well_details
      # For each well with aliquots on the plate select the pcr cycles metadata
      # { 'A1' => { 'pcr_cycles' => 16 }, 'B1' => etc. }
      @well_details ||=
        current_plate
          .wells
          .each_with_object({}) do |well, details|
            next if well.aliquots.empty?

            details[well.location] = { 'pcr_cycles' => well.attributes['pcr_cycles'] }
          end
    end
  end
end
