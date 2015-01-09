module Presenters
  class LibPcrXpPresenter < PlatePresenter
    include Presenters::Statemachine
      # The state machine for plates which has knock-on effects on the plates that can be created
    state_machine :state, :initial => :qc_complete do
      StateTransitions.inject(self)
      state :pending do
        include StateDoesNotAllowChildCreation
      end
      state :started do
        include StateDoesNotAllowChildCreation
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
      state :qc_complete do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def control_additional_creation(&block)
          yield unless child_plate_purposes.empty?
          nil
        end

        #Work out where we're heading.
        def child_plate_purposes
          plate.plate_purpose.children.select { |p| p.name == Settings.purposes[plate.plate_purpose.uuid][:selected_child_purpose] }
        end

      end
    end

    write_inheritable_attribute :has_qc_data?, true

    write_inheritable_attribute :authenticated_tab_states, {
        :pending    =>  [ 'summary-button' ],
        :started    =>  [ 'summary-button' ],
        :passed     =>  [ 'summary-button' ],
        :cancelled  =>  [ 'summary-button' ],
        :failed     =>  [ 'summary-button' ],
        :qc_complete => [ 'plate-creation-button','summary-button' ]
    }

      # The current state of the plate is delegated to the plate
    delegate :state, :to => :plate

  end
end
