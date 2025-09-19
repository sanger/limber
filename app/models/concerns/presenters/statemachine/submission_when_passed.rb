# frozen_string_literal: true

require_dependency 'presenters/statemachine'
module Presenters::Statemachine
  #
  # Presenters::Statemachine::SubmissionWhenPassed can be included in a class to provide
  # a state machine with the following behaviour:
  # - When plates are 'passed' the submission sidebar will be displayed.
  #   This sidebar allows the user to build a submission for the plate
  # - In all other states the default sidebar will be used
  # - When the plate is passed, the user will be allowed to create the child plates
  # - In all other states the user will be unable to advanced the plate
  #
  # This has been created to support the Bioscan pipeline, where it is used on the intermediate
  # Lysate plates to create library prep submissions.
  # These plates show the following states:
  # Pending: Wells have still active Lysate prep submissions.
  # Passed: The Lysate prep submissions are completed, and the plate is ready for library prep
  # submission.
  # Cancelled/Failed: Seen when all requests out of the plate have these states.
  #
  # Other states: Typically not seen in standard scenarios.
  module SubmissionWhenPassed
    extend ActiveSupport::Concern
    included do
      include Shared

      # The state machine for plates which has knock-on effects on the plates that can be created
      state_machine :state, initial: :pending do
        StateTransitions.inject(self)

        state :pending do
          include StateDoesNotAllowChildCreation
        end

        state :started do
          include StateDoesNotAllowChildCreation
        end

        state :processed_1 do
          include StateDoesNotAllowChildCreation
        end

        state :processed_2 do
          include StateDoesNotAllowChildCreation
        end

        state :processed_3 do
          include StateDoesNotAllowChildCreation
        end

        state :processed_4 do
          include StateDoesNotAllowChildCreation
        end

        state :passed do
          include StateAllowsChildCreation

          def sidebar_partial
            'submission_default'
          end
        end

        state :qc_complete, human_name: 'QC Complete' do
          include StateAllowsChildCreation
        end

        state :cancelled do
          include StateDoesNotAllowChildCreation
        end

        state :failed do
          include StateDoesNotAllowChildCreation
        end

        state :unknown do
          include StateDoesNotAllowChildCreation
        end
      end
    end
  end
end
