# frozen_string_literal: true

require_dependency 'presenters/statemachine'
module Presenters::Statemachine
  #
  # Presenters::Statemachine::SequencingSubmission can be included in a class to
  # provide a state machine with the following behaviour:
  # - When tubes are 'pending', only the default sidebar will be displayed,
  #   allowing the user to only perform manual transfers or passing.
  # - When tubes are 'passed', a combined default and submission sidebar will
  #   be displayed. This sidebar allows the user to build a submission for the
  #   tube.
  # - In all other states the default sidebar will be used.
  #
  # Other states: Typically not seen in standard scenarios.
  module SequencingSubmission
    extend ActiveSupport::Concern

    included do
      include Shared

      state_machine :state, initial: :pending do
        StateTransitions.inject(self)

        state :pending do
          include StateDoesNotAllowChildCreation
          include DoesNotAllowLibraryPassing

          def sidebar_partial
            'default'
          end
        end

        state :started do
          include StateDoesNotAllowChildCreation
          include DoesNotAllowLibraryPassing
        end

        state :passed do
          include StateDoesNotAllowChildCreation
          include TubeAllowsLibraryPassing

          def sidebar_partial
            'submission_default'
          end
        end

        state :qc_complete, human_name: 'QC Complete' do
          include StateDoesNotAllowChildCreation
          include TubeAllowsLibraryPassing
        end

        state :unknown do
          include StateDoesNotAllowChildCreation
          include DoesNotAllowLibraryPassing
        end

        state :failed do
          include StateDoesNotAllowChildCreation
          include DoesNotAllowLibraryPassing
        end

        state :cancelled do
          include StateDoesNotAllowChildCreation
          include DoesNotAllowLibraryPassing
        end
      end
    end
  end
end
