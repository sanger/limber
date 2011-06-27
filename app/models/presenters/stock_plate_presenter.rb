module Presenters
  class StockPlatePresenter < PlatePresenter
    include Presenters::Statemachine

    def control_state_change(&block)
      # You cannot change the state of the stock plate
    end
  end
end
