# frozen_string_literal: true

module Presenters
  class QcPlatePresenter < PlatePresenter
    include Presenters::Statemachine
    include StateDoesNotAllowChildCreation

    def qc_owner
      labware.creation_transfers.first.source
    end
  end
end
