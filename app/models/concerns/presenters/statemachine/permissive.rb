# frozen_string_literal: true

require_dependency 'presenters/statemachine'
module Presenters::Statemachine
  module Permissive # rubocop:todo Style/Documentation
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
