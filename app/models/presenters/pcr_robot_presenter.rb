module Presenters
  class PcrRobotPresenter < PlatePresenter
    include Presenters::Statemachine::Pcr

    write_inheritable_attribute :aliquot_partial, 'tagged_aliquot'

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    => [ 'labware-summary-button', 'robot-verification-button' ],
      :started_fx => [ 'labware-state-button', 'labware-summary-button' ],
      :started_mj => [ 'labware-state-button', 'labware-summary-button' ],
      :passed     => [ 'labware-creation-button', 'labware-state-button', 'labware-summary-button' ],
      :cancelled  => [ 'labware-summary-button' ],
      :failed     => [ 'labware-summary-button' ]
    }

    write_inheritable_attribute :robot_name, 'fx-add-tags'

  end
end
