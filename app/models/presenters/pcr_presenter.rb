module Presenters
  class PcrPresenter < PlatePresenter
    include Presenters::Statemachine::Pcr

    write_inheritable_attribute :aliquot_partial, 'tagged_aliquot'

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    => [ 'summary-button', 'plate-state-button' ],
      :started_fx => [ 'plate-state-button', 'summary-button' ],
      :started_mj => [ 'plate-state-button', 'summary-button' ],
      :passed     => [ 'plate-creation-button','summary-button', 'plate-state-button' ],
      :cancelled  => [ 'summary-button' ],
      :failed     => [ 'summary-button' ]
    }


  end
end
