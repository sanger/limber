# frozen_string_literal: true

module Presenters
  class MinimalStockPlatePresenter < MinimalPlatePresenter
    validates_with Validators::StockStateValidator, if: :pending?

    def control_state_change
      # You cannot change the state of the stock plate
    end

    def default_state_change
      # You cannot change the state of the stock plate
    end
  end
end
