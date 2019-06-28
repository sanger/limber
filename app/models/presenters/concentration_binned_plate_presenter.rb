# frozen_string_literal: true

module Presenters
  #
  # The ConcentrationBinnedPlatePresenter is used for plates that have had
  # concentration binning applied. It shows a view of the plate with colours
  # and keys indicating the various bins.
  #
  class ConcentrationBinnedPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard
    include LabwareCreators::ConcentrationBinning

    self.summary_partial = 'labware/plates/concentration_binned_summary'
    self.aliquot_partial = 'concentration_binned_aliquot'

    def binning_config
      purpose_config.fetch(:concentration_binning, {})
    end

    def bins_key
      binning_config.bins.map do |bin|
        {
          'pcr_cycles' => bin.pcr_cycles,
          'colour' => bin.colour
        }
      end
    end

    def plate_with_qc_results
      @plate_with_qc_results ||= Sequencescape::Api::V2.plate_with_custom_includes('wells.aliquots,wells.qc_results', labware.uuid)
    end

    def bin_details
      @bin_details ||= compute_bin_details
    end

    private

    def compute_bin_details
      multiplier = LabwareCreators::ConcentrationBinnedPlate.dest_plate_multiplication_factor(binning_config)
      well_amounts = LabwareCreators::ConcentrationBinnedPlate.compute_well_amounts(plate_with_qc_results, multiplier)
      LabwareCreators::ConcentrationBinnedPlate.compute_presenter_bin_details(well_amounts, binning_config)
    end
  end
end
