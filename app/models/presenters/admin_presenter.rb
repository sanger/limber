module Presenters
  class AdminPresenter < PlatePresenter
    include Presenters::Statemachine

    def lab_ware_form_details(view)
      { :url => view.admin_plate_path(self.plate), :as  => :plate }
    end

    def stock_plate?
      self.class.lookup_for(plate) == Presenters::StockPlatePresenter
    end

    # Yields any block passed to it, so that we can changed from
    # any state to any state....
    def control_state_change(&block)
      yield(all_plate_states)
      nil
    end
  end
end
