# frozen_string_literal: true

module Presenters
  #
  # This Presenter presents the user with a selection of submission options,
  # and allows them to generate corresponding Sequencescape submissions.
  # It only presents these options when certain pre-requisites are met.
  # Namely, a downstream tube labware of specified purpose must have a specified
  # state and a sequencing request of the specified type in a specific state.
  # i.e. The pipeline has completed a sequencing run already and we are looping
  # back to create a new submission.
  # Designed for Ultima where we loop back to perform rebalancing. But only after
  # the initial sequencing run has been completed.
  #
  # Submission options are defined by the submission_options config in the
  # purposes/*.yml file. Structure is:
  # <button text>:
  #   template_name: <submission template name>
  #   downstream_tube_checks:
  #     downstream_tube_purpose: <downstream tube purpose> e.g. 'UPF EqVol Norm'
  #     downstream_tube_state: <downstream tube state> e.g. 'passed'
  #     sequencing_request_type: <sequencing request type> e.g. 'ultima_sequencing'
  #     TODO: should we include 'failed' state? can we rebalance if failed? should we include 'started'? unsure of when
  #     NPG updates the state of sequencing requests
  #     sequencing_request_allowed_states: [<request state>, <request state>, etc.] e.g. ['completed', 'failed']
  #   request_options:
  #     <request_option_key>: <request_option_value>
  #     ...
  class SubmissionPlateDownstreamCompletedPresenter < PlatePresenter
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

    def allow_new_submission?
      # TODO: override
    end
  end
end
