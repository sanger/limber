module Presenters
  class QcCompletablePresenter < PlatePresenter
    include Presenters::Statemachine::QcCompletable

    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'labware-summary-button', 'labware-state-button' ],
      :started     => [ 'labware-state-button', 'labware-summary-button' ],
      :passed      => [ 'labware-state-button', 'labware-summary-button', 'well-failing-button' ],
      :qc_complete => [ 'labware-creation-button', 'labware-state-button', 'labware-summary-button' ],
      :cancelled   => [ 'labware-summary-button' ],
      :failed      => [ 'labware-summary-button' ]
    }

  end
end
