# frozen_string_literal: true

module Presenters
  # This Presenter is for stock plates where we want to be able to fail wells.
  # It is a more permissive version of the standard StockPlatePresenter.
  class FailableStockPlatePresenter < StockPlatePresenter
    self.allow_well_failure_in_states = [:passed]
  end
end
