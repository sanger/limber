# frozen_string_literal: true

module Presenters
  # Presenter for the Chromium Chip plate to disable the existing pooling tab
  # that assumes a different pooling strategy and a standard plate layout.
  class ChromiumChipPresenter < StandardPresenter
    self.pooling_tab = ''
  end
end
