# frozen_string_literal: true

module Presenters
  #
  # The SubmissionTubePresenter is used when tubes enter the process with no
  # assigned pipeline. It presents the user with a selection of workflows,
  # and allows them to generate corresponding Sequencescape submissions.
  #
  # Submission options are defined by the submission_options config in the
  # purposes/*.yml file. Structure is:
  # <button text>:
  #   template_name: <submission template name>
  #   request_options:
  #     <request_option_key>: <request_option_value>
  #     ...
  class SubmissionTubePresenter < TubePresenter
    include Presenters::Statemachine::SequencingSubmission
    include Presenters::SubmissionBehaviour
  end
end
