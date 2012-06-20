module Presenters
  class PrePcrPlatePresenter < PlatePresenter
    include Presenters::Statemachine
    state_machine :state, :initial => :pending do
      Statemachine::StateTransitions.inject(self)

      state :pending do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def control_additional_creation(&block)
          yield unless child_plate_purposes.empty?
          nil
        end

        # Returns the child plate purposes that can be created in the passed state.  Typically
        # this is only one, but it specifically excludes QC plates.
        def child_plate_purposes
          # plate.plate_purpose.children.reject { |p| p.name == 'Pulldown QC plate' }
          plate.plate_purpose.children
        end
      end

      state :started do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def control_additional_creation(&block)
          yield unless child_plate_purposes.empty?
          nil
        end

        # Returns the child plate purposes that can be created in the passed state.  Typically
        # this is only one, but it specifically excludes QC plates.
        def child_plate_purposes
          # plate.plate_purpose.children.reject { |p| p.name == 'Pulldown QC plate' }
          plate.plate_purpose.children
        end
      end

      state :passed do
        include StateDoesNotAllowChildCreation
      end
      state :failed do
        include StateDoesNotAllowChildCreation
      end
      state :cancelled do
        include StateDoesNotAllowChildCreation
      end
    end

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    =>  [ 'plate-creation-button', 'summary-button' ],
      :started    =>  [ 'plate-creation-button', 'summary-button', 'well-failing-button' ],
      :passed     =>  [ 'summary-button', 'well-failing-button' ],
      :cancelled  =>  [ 'summary-button' ],
      :failed     =>  [ 'summary-button' ]
    }

  end
end
