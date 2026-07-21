# frozen_string_literal: true

module Presenters
  #
  # Presenters::StockPlateWithNoSubmissionPresenter is used for stock plates
  # which do not need a submission to continue.
  # This is used for the scRNA Core pipeline, specifically for LRC GEM-X 5p CITE SUP Input plates.
  #
  # NB. State is determined from the InputPlate purpose class in Sequencescape, where we check for a default_state
  # (value 'passed') in the purpose configuration and use that value instead of relying on transfer requests or well
  # submission requests.
  class StockPlateWithNoSubmissionPresenter < PlatePresenter
    include Presenters::StockNoSubmissionBehaviour
    include Presenters::Statemachine::Standard

    # Allow wells to be failed
    self.allow_well_failure_in_states = [:passed]

    # Stock style class causes well state to inherit from plate state.
    self.style_class = 'stock'

    # Checks for suboptimal wells
    validates_with Validators::SuboptimalValidator
  end
end
