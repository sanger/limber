# frozen_string_literal: true

module Presenters
  #
  # The ConcentrationBinnedPlatePresenter is used for plates that have had
  # concentration binning applied. It shows a view of the plate with colours
  # and keys indicating the various bins.
  #
  class ConcentrationBinnedPlatePresenter < StandardPresenter
    include Presenters::Statemachine::Standard

    validates_with Validators::SuboptimalValidator
  end
end
