# frozen_string_literal: true

module Presenters
  class StockPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard
    include Presenters::StockBehaviour

    self.well_failure_states = []
    # Stock style class causes well state to inherit from plate state.
    self.style_class = 'stock'

    validates_with Validators::SuboptimalValidator
  end
end
