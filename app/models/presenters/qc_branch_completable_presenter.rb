module Presenters
  class QcBranchCompletablePresenter < PlatePresenter
    include Presenters::Statemachine::QcCompletable

    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'labware-summary-button', 'labware-creation-button' ],
      :started     => [ 'labware-summary-button' ],
      :passed      => [ 'labware-summary-button', 'labware-state-button', 'well-failing-button' ],
      :qc_complete => [ 'labware-summary-button', 'labware-state-button', 'labware-creation-button' ],
      :cancelled   => [ 'labware-summary-button' ],
      :failed      => [ 'labware-summary-button' ]
    }

  end
end
