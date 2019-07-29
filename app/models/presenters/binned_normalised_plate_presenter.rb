# frozen_string_literal: true

module Presenters
  #
  # The ConcentrationBinnedPlatePresenter is used for plates that have had
  # concentration binning applied. It shows a view of the plate with colours
  # and keys indicating the various bins.
  #
  class BinnedNormalisedPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    self.summary_partial = 'labware/plates/concentration_binned_summary'
    self.aliquot_partial = 'concentration_binned_aliquot'

    def binned_normalisation_config
      purpose_config.fetch(:binned_normalisation)
    end

    def binned_normalisation_calculator
      @binned_normalisation_calculator ||= Utility::BinnedNormalisationCalculator.new(binned_normalisation_config)
    end

    def bins_key
      binned_normalisation_calculator.bins_template
    end

    def plate_with_qc_results
      @plate_with_qc_results ||=
        Sequencescape::Api::V2.plate_with_custom_includes('wells.aliquots,wells.qc_results', uuid: labware.uuid)
    end

    def bin_details
      @bin_details ||= compute_bin_details
    end

    private

    def compute_bin_details
      binned_normalisation_calculator.compute_presenter_bin_details(plate_with_qc_results)
    end
  end
end
