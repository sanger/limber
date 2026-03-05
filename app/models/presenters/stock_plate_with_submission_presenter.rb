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

    # This is hard coded, need to match the SS submission template config request_type_keys
    # and Limber config submission options label, not ideal
    def button_request_type_map
      {
        'EM-seq (+ WGS) Branch - Automated Submission' => 'limber_lcm_triomics_emseq',
        'RNA-Seq Branch - Automated Submission' => 'limber_lcm_triomics_rnaseq'
      }
    end

    def active_request_types
      wells.flat_map(&:active_requests)
        .map(&:request_type_key)
        .uniq
    end

    def disable_button_for_label?(label)
      # Disable all buttons if any submission is in progress
      return true if pending_submissions?

      # Map the button label to its request type key
      request_type = button_request_type_map[label]
      # Disable only if there is an active request of this type
      request_type && active_request_types.include?(request_type)
    end
  end
end
