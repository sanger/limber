module Presenters
  class StandardRobotPresenter < StandardPresenter

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    =>  [ 'labware-summary-button', 'labware-state-button' ],
      :started    =>  [ 'labware-state-button', 'labware-summary-button' ],
      :passed     =>  [ 'labware-creation-button','labware-summary-button', 'labware-well-failing-button', 'labware-plate-state-button' ],
      :cancelled  =>  [ 'labware-summary-button' ],
      :failed     =>  [ 'labware-summary-button' ]
    }

    def robot_controlled_states
      {
      :pending => Settings.purposes[self.plate.plate_purpose.uuid][:robot]
      }
    end

    #def robot_name
    #  Settings.purposes[plate.plate_purpose.uuid][:robot]
    #end

    def plate
      self.labware
    end

  end
end
