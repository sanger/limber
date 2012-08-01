module Presenters
  class QcCapablePlatePresenter < PlatePresenter
    include Presenters::Statemachine

    write_inheritable_attribute :authenticated_tab_states, {
        :pending    =>  [ 'summary-button', 'labware-state-button' ],
        :started    =>  [ 'labware-QC-button', 'summary-button', 'labware-state-button' ],
        :passed     =>  [ 'labware-creation-button','summary-button', 'well-failing-button', 'labware-state-button' ],
        :cancelled  =>  [ 'summary-button' ],
        :failed     =>  [ 'summary-button' ]
    }

  end
end
