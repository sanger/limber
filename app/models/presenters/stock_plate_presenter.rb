module Presenters
  class StockPlatePresenter < PlatePresenter
    include Presenters::Statemachine

    def control_state_change(&block)
      # You cannot change the state of the stock plate
    end

    def control_worksheet_printing(&block)
      # you shouldn't be able to print a worksheet for a stock plate
      # either...
    end
  end
end
