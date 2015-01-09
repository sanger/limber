class Presenters::FinalPooledRobotPresenter < Presenters::FinalPooledPresenter

  write_inheritable_attribute :authenticated_tab_states, {
    :pending    =>  [ 'summary-button', 'robot-verification-button' ],
    :started    =>  [ 'plate-QC-button', 'summary-button', 'plate-state-button' ],
    :passed     =>  [ 'summary-button', 'plate-state-button' ],
    :cancelled  =>  [ 'summary-button' ],
    :failed     =>  [ 'summary-button' ]
  }

  write_inheritable_attribute :robot_name, 'nx8-post-cap-lib-pool'

end
