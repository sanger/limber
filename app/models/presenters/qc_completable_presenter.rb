module Presenters
  class QcCompletablePresenter < PlatePresenter
    include Presenters::Statemachine::QcCompletable

    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'summary-button', 'labware-state-button' ],
      :started     => [ 'labware-state-button', 'summary-button' ],
      :passed      => [ 'labware-state-button', 'summary-button', 'well-failing-button' ],
      :qc_complete => [ 'labware-creation-button','summary-button' ],
      :cancelled   => [ 'summary-button' ],
      :failed      => [ 'summary-button' ]
    }

  end
end
