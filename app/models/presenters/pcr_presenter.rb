module Presenters
  class PcrPresenter < PlatePresenter
    include Presenters::Statemachine::Pcr

    write_inheritable_attribute :aliquot_partial, 'tagged_aliquot'

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    => [ 'summary-button', 'labware-state-button' ],
      :started_fx => [ 'labware-state-button', 'summary-button' ],
      :started_mj => [ 'labware-state-button', 'summary-button' ],
      :passed     => [ 'labware-creation-button','summary-button', 'labware-state-button' ],
      :cancelled  => [ 'summary-button' ],
      :failed     => [ 'summary-button' ]
    }


  end
end
