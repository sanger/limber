# frozen_string_literal: true

module Presenters
  class StockPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Standard
    include Presenters::StockBehaviour

    self.well_failure_states = []

    validates_with Validators::SuboptimalValidator
  end
end
