module Presenters
  class StandardRobotPresenter < StandardPresenter

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    =>  [ 'summary-button', 'robot-verification-button' ],
      :started    =>  [ 'plate-state-button', 'summary-button' ],
      :passed     =>  [ 'plate-creation-button','summary-button', 'well-failing-button', 'plate-state-button' ],
      :cancelled  =>  [ 'summary-button' ],
      :failed     =>  [ 'summary-button' ]
    }

    def robot_name
      Settings.purposes[plate.plate_purpose.uuid][:robot]
    end

  end
end
