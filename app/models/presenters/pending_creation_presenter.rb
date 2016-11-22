# frozen_string_literal: true

module Presenters
  class PendingCreationPresenter < PlatePresenter
    include Presenters::Statemachine::PendingPlateCreation

    self.aliquot_partial = 'tagged_aliquot'
  end
end
