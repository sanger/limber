# frozen_string_literal: true

module Presenters::Statemachine
  # State transitions are common across all of the statemachines.
  module StateTransitions
    def self.inject(base)
      base.instance_eval do
        event :take_default_path, human_name: 'Manual Transfer' do
          transition pending: :passed
          transition started: :passed
        end

        event :transfer do
          transition %i[pending started] => :passed
        end

        event :cancel do
          transition %i[pending started passed] => :cancelled
        end

        # We use `fail_labware` here as `fail` is defined on Object (its an alias for `raise`)
        # Statemachines ends up throwing a warning, which while we can disable, we're probably
        # safer avoiding the conflict, especially as we don't actually call these methods directly
        # anyway.
        event :fail_labware, human_name: 'Fail' do
          transition %i[pending started passed] => :failed
        end
      end
    end
  end
end
