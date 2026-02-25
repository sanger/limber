# frozen_string_literal: true

module Presenters
  #
  # Presenters::StockPlateWithSubmissionPresenter is used for stock plates
  # which have a submission sidebar when passed.
  # This is used for the LCM Triomics pipeline, where the stock plate is used as
  # the input plate for the submission, and the user should be able to create
  # the submission when the plate is passed.
  #
  class StockPlateWithSubmissionPresenter < PlatePresenter
    include Presenters::Statemachine::Submission
    include Presenters::SubmissionBehaviour
    include Presenters::StockBehaviour
    include Presenters::StateChangeless
    include Presenters::Statemachine::DoesNotAllowLibraryPassing
    include Presenters::Statemachine::SubmissionWhenPassed

    self.allow_well_failure_in_states = []
    self.style_class = 'stock'

    validates_with Validators::SuboptimalValidator
    validates_with Validators::ActiveRequestValidator

    def allow_new_submission?
      true
    end
  end
end
