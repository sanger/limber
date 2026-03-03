# frozen_string_literal: true

module Presenters
  #
  # Presenters::StockPlateWithSubmissionPresenter is used for stock plates
  # which have a submission sidebar when passed.
  # This is used for the LCM Triomics pipeline, where the stock plate is used as
  # the input plate for the submission, and the user should be able to create
  # the submission when the plate is passed.
  #
  class StockPlateWithSubmissionPresenter < SubmissionPlatePresenter
    include Presenters::StockBehaviour
    include Presenters::Statemachine::SubmissionWhenPassed

    validates_with Validators::SuboptimalValidator
    validates_with Validators::ActiveRequestValidator

    def allow_new_submission?
      true
    end

    def submission_in_progress?
      labware.requests_in_progress.any?
    end

    def requests_pending?
      labware.all_requests.any?(&:pending?)
    end

    def disable_workflow_creation?
      return true if pending_submissions? || requests_pending?

      false
    end
  end
end
