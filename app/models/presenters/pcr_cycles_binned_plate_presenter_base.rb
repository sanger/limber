# frozen_string_literal: true

module Presenters
  #
  # The PcrCyclesBinnedPlatePresenter is used for plates that have had
  # pcr cycle binning applied. It shows a view of the plate with colours
  # and keys indicating the various bins.
  # This is the base class for the PcrCyclesBinnedPlatePresenter and should
  # not be used directly.
  # NB. Once DuplexSeq is converted to use the new request poly_metadata, this
  # subclassing can be removed and the PcrCyclesBinnedPlateUsingRequestMetadataPresenter
  # version will be the only version needed.
  #
  class PcrCyclesBinnedPlatePresenterBase < PlatePresenter
    include Presenters::Statemachine::Standard

    self.summary_partial = 'labware/plates/binned_summary'
    self.aliquot_partial = 'binned_aliquot'

    validates_with Validators::ActiveRequestValidator

    def current_plate
      @current_plate ||= Sequencescape::Api::V2.plate_with_custom_includes(current_plate_includes, uuid: labware.uuid)
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

    def current_plate_includes
      raise 'Method current_plate_includes must be implemented in a subclass of PcrCyclesBinnedPlatePresenterBase'
    end

    private

    def well_details
      raise 'Method well_details must be implemented in a subclass of PcrCyclesBinnedPlatePresenterBase'
    end
  end
end
