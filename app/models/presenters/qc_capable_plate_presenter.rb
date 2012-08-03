module Presenters
  class QcCapablePlatePresenter < PlatePresenter
    include Presenters::Statemachine

    write_inheritable_attribute :authenticated_tab_states, {
        :pending    =>  [ 'labware-summary-button', 'labware-state-button' ],
        :started    =>  [ 'labware-QC-button', 'labware-summary-button', 'labware-state-button' ],
        :passed     =>  [ 'labware-creation-button','labware-summary-button', 'well-failing-button', 'labware-state-button' ],
        :cancelled  =>  [ 'labware-summary-button' ],
        :failed     =>  [ 'labware-summary-button' ]
    }

  end
end
