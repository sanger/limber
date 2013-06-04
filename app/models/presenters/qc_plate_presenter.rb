module Presenters
  class QcPlatePresenter < PlatePresenter

   include Presenters::Statemachine

    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'labware-summary-button','labware-state-button' ],
      :started     => [ 'labware-summary-button','labware-state-button' ],
      :passed      => [ 'labware-summary-button' ],
    }

    def has_qc_data?; labware.passed?; end

    def control_additional_creation(&block)
      nil
    end

    def qc_owner
      labware.creation_transfers.first.source
    end

  end
end
