module Presenters
  class QcCapablePlatePresenter < PlatePresenter
    include Presenters::Statemachine

    write_inheritable_attribute :authenticated_tab_states, {
        :pending    =>  [ 'summary-button', 'plate-state-button' ],
        :started    =>  [ 'plate-QC-button', 'summary-button', 'plate-state-button' ],
        :passed     =>  [ 'plate-creation-button','summary-button', 'well-failing-button', 'plate-state-button' ],
        :cancelled  =>  [ 'summary-button' ],
        :failed     =>  [ 'summary-button' ]
    }

  end
end
