module Presenters
  class StockPlatePresenter < PlatePresenter
    include Presenters::Statemachine

    write_inheritable_attribute :authenticated_tab_states, {
        :pending    =>  [ 'labware-summary-button' ],
        :started    =>  [ 'labware-summary-button' ],
        :passed     =>  [ 'labware-creation-button','labware-summary-button' ],
        :cancelled  =>  [ 'labware-summary-button' ],
        :failed     =>  [ 'labware-summary-button' ]
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
