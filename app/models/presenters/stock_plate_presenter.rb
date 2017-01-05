# frozen_string_literal: true

module Presenters
  class StockPlatePresenter < PlatePresenter
    include Presenters::Statemachine

    self.well_failure_states = [:passed]

    def control_state_change(&_block)
      # You cannot change the state of the stock plate
    end

    def default_state_change(&_block)
      # You cannot change the state of the stock plate
    end
  end
end
