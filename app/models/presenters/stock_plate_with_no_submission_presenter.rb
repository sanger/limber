# frozen_string_literal: true

module Presenters
  #
  # Presenters::StockPlateWithNoSubmissionPresenter is used for stock plates
  # which do not need a submission to continue.
  # This is used for the scRNA Core pipeline, specifically for LRC GEM-X 5p CITE SUP Input plates.
  #
  class StockPlateWithNoSubmissionPresenter < PlatePresenter
    include Presenters::StockNoSubmissionBehaviour
    include Presenters::Statemachine::Permissive

    validates_with Validators::SuboptimalValidator

    def allow_new_submission?
      true
    end

    def state
      'passed'
    end
  end
end
