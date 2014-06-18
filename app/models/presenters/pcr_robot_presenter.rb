module Presenters
  class PcrRobotPresenter < PlatePresenter
    include Presenters::Statemachine::Pcr

    write_inheritable_attribute :aliquot_partial, 'tagged_aliquot'

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    => [ 'labware-summary-button', 'labware-state-button'],
      :started_fx => [ 'labware-summary-button', 'labware-state-button'],
      :started_mj => [ 'labware-summary-button', 'labware-state-button'],
      :passed     => [ 'labware-summary-button', 'labware-state-button', 'labware-creation-button'  ],
      :cancelled  => [ 'labware-summary-button' ],
      :failed     => [ 'labware-summary-button' ]
    }

    write_inheritable_attribute :robot_controlled_states, {
      :pending => 'fx-add-tags'
    }

  end
end
