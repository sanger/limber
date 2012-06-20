module Presenters
  class IlluminaBShearedPlatePresenter < PlatePresenter
    include Presenters::Statemachine
    state_machine :state, :initial => :pending do
      Statemachine::StateTransitions.inject(self)

      state :pending do
        include StateDoesNotAllowChildCreation

      end
      state :started do
        # If the shearing plate has no children then allow creation of
        # the Pre PCR plate, otherwise only allow new PCR plates to be
        # produced.
        def child_plate_purposes
          child_types = plate.plate_purpose.children.each_with_object({}) { |pp,child_types|
            (child_types[pp.name] = pp) if ['ILB_STD_PCR', 'ILB_STD_PREPCR'].include?(pp.name)
          }


          plate.source_transfers.empty? ? [child_types['ILB_STD_PREPCR']] : [child_types['ILB_STD_PCR']]
        end
      end
      state :passed do

      end
      state :failed do

      end
      state :cancelled do

      end
    end

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    =>  [ 'summary-button', 'plate-state-button' ],
      :started    =>  [ 'plate-creation-button', 'summary-button', 'plate-state-button' ],
      :passed     =>  [ 'plate-creation-button','summary-button', 'well-failing-button', 'plate-state-button' ],
      :cancelled  =>  [ 'summary-button' ],
      :failed     =>  [ 'summary-button' ]
    }

  end
end
