# frozen_string_literal: true

require_dependency 'presenters/statemachine'
module Presenters::Statemachine
  #
  # Presenters::Statemachine::PermissiveSubmission can be included in a class to
  # provide a state machine with the following behaviour:
  # - When plates are 'passed', a combined default and submission sidebar will
  #   be displayed. This sidebar allows the user to build a submission for the
  #   plate, while still allowing child plates to be created.
  # - When plates are 'pending', only the default sidebar will be displayed,
  #   allowing the user to create the child plates.
  # - In all other states the default sidebar will be used.
  # - In all states the library passing is not permitted.
  #
  # Typically this state machine should be used in conjunction with an input
  # plate purpose. {file:docs/purposes_yaml_files.md See the purposes yaml configuration.}
  # Purposes with input_plate set to true use the PlatePurpose::Input class in sequencescape.
  # These plates show the following states:
  # Pending: No submission made, or some wells with samples have no submissions
  # Passed: Submissions made, and the plate is ready to proceed
  # Cancelled/Failed: Seen when all requests out of the plate have these states.
  #
  # Other states: Typically not seen in standard scenarios.
  module PermissiveSubmission
    extend ActiveSupport::Concern

    included do
      include Shared

      # The state machine for plates which has knock-on effects on the plates that can be created
      state_machine :state, initial: :pending do
        StateTransitions.inject(self)

        # These are the states, which are really the only things we need ...
        state :pending do
          include StateAllowsChildCreation
          include DoesNotAllowLibraryPassing

          def sidebar_partial
            'default'
          end
        end

        state :started do
          include StateAllowsChildCreation
          include DoesNotAllowLibraryPassing
        end

        state :processed_1 do
          include StateAllowsChildCreation
          include DoesNotAllowLibraryPassing
        end

        state :processed_2 do
          include StateAllowsChildCreation
          include DoesNotAllowLibraryPassing
        end

        state :processed_3 do
          include StateAllowsChildCreation
          include DoesNotAllowLibraryPassing
        end

        state :processed_4 do
          include StateAllowsChildCreation
          include DoesNotAllowLibraryPassing
        end

        state :passed do
          include StateAllowsChildCreation
          include DoesNotAllowLibraryPassing

          def sidebar_partial
            'submission_default'
          end
        end

        state :qc_complete, human_name: 'QC Complete' do
          include StateAllowsChildCreation
          include DoesNotAllowLibraryPassing
        end

        state :cancelled do
          include StateDoesNotAllowChildCreation
          include DoesNotAllowLibraryPassing
        end

        state :failed do
          include StateDoesNotAllowChildCreation
          include DoesNotAllowLibraryPassing
        end
      end
    end
  end
end
