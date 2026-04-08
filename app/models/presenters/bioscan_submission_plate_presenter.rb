# frozen_string_literal: true

module Presenters
  #
  # The BioscanSubmissionPlatePresenter is used specifically for the LBSN-96 Lysate Input plates
  # in the Bioscan pipeline.
  # There are two modes of operation here:
  # 1. For the first run, these plates enter the process with no assigned pipeline. It presents
  # the user with a selection of workflows configured in the purposes yaml file, and allows the
  # user to generate a corresponding Sequencescape Submission. For Bioscan the only option is for
  # Bioscan Library Prep. The user clicks this and a submission is generated. The plate is now in
  # 'passed' state and the child PCR 1 plate can be created as we have active requests.
  # 2. For subsequent runs, the plates are in passed state already and have a completed library
  # prep submission from the initial run. In this case, the code checks that we have no active
  # submissions (i.e. requests are all passed, failed or cancelled) and allows the user to create
  # a new Submission. The plate remains in state 'passed' but now the child PCR 1 plate can be
  # created as we have active requests. We override the active_pipelines method to achieve this.
  #
  # Submission options are defined by the submission_options config in the
  # purposes/*.yml file. Structure is:
  # <button text>:
  #   template_name: <submission template name>
  #   request_options:
  #     <request_option_key>: <request_option_value>
  #     ...
  #
  class BioscanSubmissionPlatePresenter < PlatePresenter
    include Presenters::Statemachine::SubmissionWhenInputAndWhenPassed
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

    # Checks for in progress requests before allowing the child creation button to show
    def active_pipelines
      Settings.pipelines.active_pipelines_for_in_progress_requests(labware)
    end
  end
end
