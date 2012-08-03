module Presenters
  class PrePcrPlatePresenter < PlatePresenter
    include Presenters::Statemachine

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    =>  [ 'labware-summary-button', 'labware-creation-button' ],
      :started    =>  [ 'labware-creation-button', 'labware-summary-button', 'well-failing-button' ],
      :passed     =>  [ 'labware-summary-button', 'well-failing-button', 'labware-creation-button'],
      :cancelled  =>  [ 'labware-summary-button' ],
      :failed     =>  [ 'labware-summary-button' ]
    }

    state_machine :state, :initial => :pending do
      Statemachine::StateTransitions.inject(self)

      state :pending do
        def control_additional_creation(&block)
          yield unless child_purposes.empty?
          nil
        end

        def child_purposes
          plate.plate_purpose.children
        end
      end

      state :started do
        StateDoesNotAllowChildCreation
      end

      state :passed do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def control_additional_creation(&block)
          yield unless child_purposes.empty?
          nil
        end

        # Returns the child plate purposes that can be created in the passed state.
        def child_purposes
          plate.plate_purpose.children
        end
      end

      state :failed do
        include StateDoesNotAllowChildCreation
      end
      state :cancelled do
        include StateDoesNotAllowChildCreation
      end
    end


  end
end
