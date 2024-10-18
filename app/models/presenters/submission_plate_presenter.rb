# frozen_string_literal: true

module Presenters
  #
  # The SubmissionPlatePresenter is used when plates enter the process with no
  # assigned pipeline. It presents the user with a selection of workflows,
  # and allows them to generate corresponding Sequencescape submissions. Once
  # these submissions are passed, the plate behaves like a standard stock plate.
  #
  # Submission options are defined by the submission_options config in the
  # purposes/*.yml file. Structure is:
  # <button text>:
  #   template_name: <submission template name>
  #   request_options:
  #     <request_option_key>: <request_option_value>
  #     ...
  class SubmissionPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Submission
    include Presenters::Statemachine::DoesNotAllowLibraryPassing
    include Presenters::SubmissionBehaviour
    include Presenters::StateChangeless

    self.allow_well_failure_in_states = []

    # Stock style class causes well state to inherit from plate state.
    self.style_class = 'stock'

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
