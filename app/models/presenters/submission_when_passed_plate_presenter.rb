# frozen_string_literal: true

module Presenters
  #
  # The SubmissionWhenPassedPlatePresenter is used when plates are just finishing one
  # pipeline and need to start a second. It presents the user with a selection of workflows,
  # and allows them to generate corresponding Sequencescape submissions.
  #
  # It was developed for Bioscan Lysate plates, where the lysate prep submission is still
  # active until the plate is passed. Once the plate is passed, the user can create a
  # library prep submission.
  #
  # Submission options are defined by the submission_options config in the
  # purposes/*.yml file. Structure is:
  # <button text>:
  #   template_name: <submission template name>
  #   request_options:
  #     <request_option_key>: <request_option_value>
  #     ...
  class SubmissionWhenPassedPlatePresenter < PlatePresenter
    include Presenters::Statemachine::SubmissionWhenPassed
    include Presenters::Statemachine::DoesNotAllowLibraryPassing
    include Presenters::SubmissionBehaviour

    self.summary_items = {
      'Barcode' => :barcode,
      'Number of wells' => :number_of_wells,
      'Plate type' => :purpose_name,
      'Current plate state' => :state,
      'Input plate barcode' => :input_barcode,
      'Created on' => :created_on
    }
  end
end
