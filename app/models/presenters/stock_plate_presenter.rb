# frozen_string_literal: true

module Presenters
  class StockPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    self.well_failure_states = [:passed]

    validates_with Validators::SuboptimalValidator
    validates_with Validators::StockStateValidator, if: :pending?

    def control_state_change
      # You cannot change the state of the stock plate
    end

    def default_state_change
      # You cannot change the state of the stock plate
    end
  end
end
