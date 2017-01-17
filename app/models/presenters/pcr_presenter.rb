# frozen_string_literal: true

module Presenters
  # Standard presenter, but renders tags.
  # Could probably get rid of this.
  class PcrPresenter < StandardPresenter
    self.aliquot_partial = 'tagged_aliquot'
  end
end
