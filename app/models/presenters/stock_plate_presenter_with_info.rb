# frozen_string_literal: true

#
module Presenters
  # A stock plate presenter with additional informational messages.
  # This subclass of StockPlatePresenter adds specific informational messages
  # to provide additional context information to the user.
  class StockPlatePresenterWithInfo < StockPlatePresenter
    def initialize(*args)
      super
      add_info_message("Please ensure you use the CITE-seq-compatible primer " \
                       "when working with 'LRC GEM-X 5p GEMs Input CITE' plates")
    end
  end
end
