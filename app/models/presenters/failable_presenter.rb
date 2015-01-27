module Presenters
  class FailablePresenter < StandardPresenter

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    =>  [ 'labware-summary-button', 'labware-state-button' ],
      :started    =>  [ 'labware-state-button', 'labware-summary-button' ],
      :passed     =>  [ 'labware-creation-button','labware-summary-button', 'labware-well-failing-button', 'labware-plate-state-button' ],
      :cancelled  =>  [ 'labware-summary-button' ],
      :failed     =>  [ 'labware-summary-button' ]
    }

  end
end
