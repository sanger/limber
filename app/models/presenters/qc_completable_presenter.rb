module Presenters
  class QcCompletablePresenter < PlatePresenter
    include Presenters::Statemachine::QcCompletable

    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'summary-button', 'plate-state-button' ],
      :started     => [ 'plate-state-button', 'summary-button' ],
      :passed      => [ 'plate-state-button', 'summary-button', 'well-failing-button' ],
      :qc_complete => [ 'plate-creation-button','summary-button' ],
      :cancelled   => [ 'summary-button' ],
      :failed      => [ 'summary-button' ]
    }

  end
end
