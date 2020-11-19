# frozen_string_literal: true

require_dependency 'presenters/statemachine'
module Presenters::Statemachine
  module Submission # rubocop:todo Style/Documentation
    extend ActiveSupport::Concern
    included do
      include Shared

      # The state machine for plates which has knock-on effects on the plates that can be created
      state_machine :state, initial: :pending do
        StateTransitions.inject(self)

        # These are the states, which are really the only things we need ...
        state :pending do
          include StateDoesNotAllowChildCreation

          def sidebar_partial
            'submission'
          end
        end

        state :started do
          include StateDoesNotAllowChildCreation
        end

        state :processed_1 do
          include StateAllowsChildCreation
        end

        state :processed_2 do
          include StateDoesNotAllowChildCreation
        end

        state :passed do
          include StateAllowsChildCreation
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
