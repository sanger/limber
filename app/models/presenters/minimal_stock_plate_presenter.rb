# frozen_string_literal: true

module Presenters
  class MinimalStockPlatePresenter < MinimalPlatePresenter # rubocop:todo Style/Documentation
    include Presenters::StockBehaviour
  end
end
