# frozen_string_literal: true

require_dependency 'presenters/statemachine'
module Presenters::Statemachine
  module Permissive
    def self.included(base)
      base.class_eval do
        include Shared

        # The state machine for plates which has knock-on effects on the plates that can be created
        state_machine :state, initial: :pending do
          StateTransitions.inject(self)

          # These are the states, which are really the only things we need ...
          state :pending do
            include StateAllowsChildCreation
            include DoesNotAllowLibraryPassing
          end

          state :started do
            include StateAllowsChildCreation
            include DoesNotAllowLibraryPassing
          end

          state :passed do
            include StateAllowsChildCreation
            include DoesNotAllowLibraryPassing
          end

          state :qc_complete, human_name: 'QC Complete' do
            include StateAllowsChildCreation
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
end
