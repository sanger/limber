# frozen_string_literal: true

module Presenters
  #
  # The SubmissionTubePresenter is used when tubes are at the end of a pipeline
  # and allows them to generate corresponding Sequencescape sequencing submissions.
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
