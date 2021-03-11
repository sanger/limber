# frozen_string_literal: true

module Presenters::Statemachine
  # State transitions are common across all of the statemachines.
  module StateTransitions
    def self.inject(base) # rubocop:todo Metrics/MethodLength
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

        event :fail do
          transition %i[pending started passed] => :failed
        end
      end
    end
  end
end
