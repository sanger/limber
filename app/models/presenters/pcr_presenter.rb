module Presenters
  class PcrPresenter < PlatePresenter
    include Presenters::Statemachine::Shared

    write_inheritable_attribute :aliquot_partial, 'tagged_aliquot'

    write_inheritable_attribute :authenticated_tab_states, {
      :pending    => [ 'summary-button', 'plate-state-button' ],
      :started_fx => [ 'plate-state-button', 'summary-button' ],
      :started_mj => [ 'plate-state-button', 'summary-button' ],
      :passed     => [ 'plate-creation-button','summary-button', 'plate-state-button' ],
      :cancelled  => [ 'summary-button' ],
      :failed     => [ 'summary-button' ]
    }

    state_machine :state, :initial => :pending do

      event :take_default_path do
        transition :pending    => :started_fx
        transition :started_fx => :started_mj
        transition :started_mj => :passed
      end

      event :pass do
        transition [ :pending, :started_mj ] => :passed
      end

      # These are the states, which are really the only things we need ...
      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
      end
      
      state :started_fx, :human_name => 'FX robot started' do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :started_mj, :human_name => 'MJ robot started' do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def control_additional_creation(&block)
          yield unless child_purposes.empty?
          nil
        end

        # Returns the child plate purposes that can be created in the qc_complete state.
        def child_purposes
          plate.plate_purpose.children
        end
      end

      state :failed do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :cancelled do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      event :fail do
        transition [ :passed ] => :failed
      end

      event :cancel do
        transition [ :pending, :started_fx, :started_mj, :passed, :failed ] => :cancelled
      end
    end

    # The current state of the plate is delegated to the plate
    delegate :state, :to => :plate

  end
end
