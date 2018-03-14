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
      end
    end
  end
end
