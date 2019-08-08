# frozen_string_literal: true

module Presenters
  #
  # The ConcentrationBinnedPlatePresenter is used for plates that have had
  # concentration binning applied. It shows a view of the plate with colours
  # and keys indicating the various bins.
  #
  class ConcentrationBinnedPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    PLATE_WITH_QC_RESULTS_INCLUDES = 'wells.aliquots,wells.qc_results'

    self.summary_partial = 'labware/plates/concentration_binned_summary'
    self.aliquot_partial = 'concentration_binned_aliquot'

    def binning_config
      purpose_config.fetch(:concentration_binning)
    end

    def dilution_calculator
      @dilution_calculator ||= Utility::ConcentrationBinningCalculator.new(binning_config)
    end

    def bins_key
      dilution_calculator.bins_template
    end

    def plate_with_qc_results
      @plate_with_qc_results ||=
        Sequencescape::Api::V2.plate_with_custom_includes(PLATE_WITH_QC_RESULTS_INCLUDES, uuid: labware.uuid)
    end

    def bin_details
      @bin_details ||= compute_bin_details
    end

    private

    def compute_bin_details
      dilution_calculator.compute_presenter_bin_details(plate_with_qc_results)
    end
  end
end
