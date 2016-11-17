# frozen_string_literal: true

module Presenters
  class PcrPresenter < StandardPresenter
    self.aliquot_partial = 'tagged_aliquot'
  end
end
