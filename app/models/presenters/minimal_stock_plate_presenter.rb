# frozen_string_literal: true

module Presenters
  # A stock plate presenter is used for plates just entering the pipeline.
  # It shows a preview of the plate, but prevents well failure and state changes.
  # In addition it also detects common scenarios which may indicate problems
  # with the submission.
  # State of stock plates is a little complicated currently, as it can't depend
  # on transfer requests into the plate. As a result, wells on stock plates may
  # have a state of 'unknown.' As a result, stock wells inherit their styling
  # from the plate itself.
  #
  # This minimal version has a simpler GUI with fewer tabs.
  class MinimalStockPlatePresenter < MinimalPlatePresenter
    include Presenters::StockBehaviour
  end
end
