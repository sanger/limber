module Presenters
  class StockPlatePresenter < PlatePresenter
    include Presenters::Statemachine

    write_inheritable_attribute :authenticated_tab_states, {
        :pending    =>  [ 'summary-button' ],
        :started    =>  [ 'summary-button' ],
        :passed     =>  [ 'plate-creation-button','summary-button' ],
        :cancelled  =>  [ 'summary-button' ],
        :failed     =>  [ 'summary-button' ]
    }

    def control_state_change(&block)
      # You cannot change the state of the stock plate
    end

    def control_worksheet_printing(&block)
      # you shouldn't be able to print a worksheet for a stock plate
      # either...
    end
  end
end
