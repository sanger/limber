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

    def active_request_types
      wells.flat_map(&:active_requests)
        .map(&:request_type_key)
        .uniq
    end

    def template_request_type(uuid)
      template = Sequencescape::Api::V2::SubmissionTemplate.find_by_uuid(uuid)
      template.request_type_keys.first
    end

    def disable_button_for_submission?(submission)
      return true if pending_submissions?

      request_type = template_request_type(submission.template_uuid)
      active_request_types.include?(request_type)
    end

  end
end
