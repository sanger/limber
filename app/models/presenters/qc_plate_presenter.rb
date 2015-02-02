module Presenters
  class QcPlatePresenter < PlatePresenter

   include Presenters::Statemachine
   include StateDoesNotAllowChildCreation

    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'labware-summary-button', 'labware-state-button' ],
      :started     => [ 'labware-state-button', 'labware-summary-button' ],
      :passed      => [ 'labware-summary-button' ],
    }

    def has_qc_data?; labware.passed?; end

    def qc_owner
      labware.creation_transfers.first.source
    end

  end
end
