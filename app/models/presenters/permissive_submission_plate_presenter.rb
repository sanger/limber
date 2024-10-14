# frozen_string_literal: true

module Presenters
  #
  # TODO: Edit this to better reflect reality!
  #
  # The PermissiveSubmissionPlatePresenter is used when plates enter the process with no
  # assigned pipeline. It presents the user with a selection of workflows,
  # and allows them to generate corresponding Sequencescape submissions. Once
  # these submissions are passed, the plate behaves like a standard stock plate.
  # Otherwise it includes aspects of the PermissivePresenter and allows plates to
  # be created even when the plate is pending.
  #
  # Submission options are defined by the submission_options config in the
  # purposes/*.yml file. Structure is:
  # <button text>:
  #   template_name: <submission template name>
  #   request_options:
  #     <request_option_key>: <request_option_value>
  #     ...
  class PermissiveSubmissionPlatePresenter < PlatePresenter
    include Presenters::Statemachine::PermissiveSubmission
    include Presenters::SubmissionBehaviour

    validates_with Validators::SuboptimalValidator
    validates_with Validators::ActiveRequestValidator

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
