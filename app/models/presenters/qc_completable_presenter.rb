module Presenters
  class QcCompletablePresenter < PlatePresenter
    include Presenters::Statemachine


    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'summary-button', 'plate-state-button' ],
      :started     => [ 'plate-state-button', 'summary-button' ],
      :passed      => [ 'plate-state-button', 'summary-button', 'well-failing-button' ],
      :qc_complete => [ 'plate-creation-button','summary-button' ],
      :cancelled   => [ 'summary-button' ],
      :failed      => [ 'summary-button' ]
    }

    state_machine :state, :initial => :pending do
      event :start do
        transition :pending => :started
      end

      event :take_default_path do
        transition :pending => :started
        transition :started => :passed
        transition :passed  => :qc_complete
      end

      event :pass do
        transition [ :pending, :started ] => :passed
      end

      event :qc_complete do
        transition :passed => :qc_complete
      end

      state :passed do
        include StateDoesNotAllowChildCreation
      end

      state :qc_complete, :human_name => 'QC Complete' do
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

      event :fail do
        transition [ :passed ] => :failed
      end

      event :cancel do
        transition [ :pending, :started, :passed, :failed ] => :cancelled
      end
    end

  end
end
