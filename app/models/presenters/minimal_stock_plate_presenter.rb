# frozen_string_literal: true

module Presenters
  class MinimalStockPlatePresenter < MinimalPlatePresenter
    include Presenters::StockBehaviour
  end
end
