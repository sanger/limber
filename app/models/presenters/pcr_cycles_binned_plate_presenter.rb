# frozen_string_literal: true

module Presenters
  #
  # The PcrCyclesBinnedPlatePresenter is used for plates that have had
  # pcr cycle binning applied. It shows a view of the plate with colours
  # and keys indicating the various bins.
  #
  class PcrCyclesBinnedPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    CURRENT_PLATE_INCLUDES = 'wells.aliquots,wells.qc_results,wells.aliquots.request'
    PCR_CYCLES_NOT_PRESENT = 'expected to be present for wells in the plate.'

    self.summary_partial = 'labware/plates/binned_summary'
    self.aliquot_partial = 'binned_aliquot'

    validates_with Validators::ActiveRequestValidator

    validates :pcr_cycles, length: { minimum: 1, message: PCR_CYCLES_NOT_PRESENT }

    def current_plate
      @current_plate ||= Sequencescape::Api::V2.plate_with_custom_includes(CURRENT_PLATE_INCLUDES, uuid: labware.uuid)
    end

    def dilutions_calculator
      @dilutions_calculator ||= Utility::PcrCyclesBinningCalculator.new(request_metadata_details)
    end

    def bins_key
      dilutions_calculator.presenter_bins_key
    end

    def bin_details
      @bin_details ||= dilutions_calculator.compute_presenter_bin_details
    end

    private

    def skip_validation_for_single_pcr_cycle_for_all_wells?
      true
    end

    def request_metadata_details
      # For each well with aliquots on the plate select the pcr cycles metadata
      # { 'A1' => { 'pcr_cycles' => 16 }, 'B1' => etc. }
      @request_metadata_details ||=
        current_plate
          .wells
          .each_with_object({}) do |well, details|
            next if well.aliquots.empty?

            # extract pcr_cycles from well.aliquots.first outer request
            details[well.location] = { 'pcr_cycles' => well.aliquots.first.request.pcr_cycles }
          end
    end
  end
end
