# frozen_string_literal: true
module Presenters
  # Presenter for the ChromiumChipX plate to disable the existing pooling tab
  # that assumes a different pooling strategy and a standard plate layout.
  class ChromiumChipXPresenter < StandardPresenter
    self.pooling_tab = ''
  end
end
