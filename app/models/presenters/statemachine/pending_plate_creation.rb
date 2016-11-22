# frozen_string_literal: true

module Presenters
  module Statemachine
    module PendingPlateCreation
      def self.included(base)
        base.class_eval do
          include Presenters::Statemachine::Shared

          state_machine :state, initial: :pending do
            event :take_default_path do
              transition pending: :passed
            end

            # These are the states, which are really the only things we need ...
            state :pending do
              include Statemachine::StateAllowsChildCreation
            end

            state :passed do
              include Statemachine::StateDoesNotAllowChildCreation
            end

            state :cancelled do
              include Statemachine::StateDoesNotAllowChildCreation
            end

            event :cancel do
              transition [:pending, :passed] => :cancelled
            end
          end
        end
      end
    end
  end
end
