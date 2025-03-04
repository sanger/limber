# frozen_string_literal: true

#
module Presenters
  # A stock plate presenter with additional informational messages.
  # This subclass of StockPlatePresenter adds specific informational messages
  # to provide additional context information to the user.
  class StockPlatePresenterWithInfo < StockPlatePresenter
    def initialize(*args)
      super
      messages = purpose_config.dig(:presenter_class, :args, :messages)
      messages&.each { |message| add_info_message(message) }
    end
  end
end
