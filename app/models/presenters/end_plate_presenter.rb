module Presenters
  ##
  # Presents a dead-end plate with no children
  class EndPlatePresenter < StandardPresenter

    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'labware-summary-button', 'labware-state-button' ],
      :started     => [ 'labware-state-button',   'labware-summary-button' ],
      :passed      => [ 'labware-summary-button' ],
    }

  end
end
