class Presenters::FinalPooledPresenter < Presenters::PooledPresenter
  write_inheritable_attribute :summary_partial, 'lab_ware/plates/pooled_into_tubes_plate'
  write_inheritable_attribute :printing_partial, 'lab_ware/plates/tube_printing'

  write_inheritable_attribute :authenticated_tab_states, {
    :pending    =>  [ 'summary-button', 'plate-state-button' ],
    :started    =>  [ 'plate-QC-button', 'summary-button', 'plate-state-button' ],
    :passed     =>  [ 'summary-button', 'plate-state-button' ],
    :cancelled  =>  [ 'summary-button' ],
    :failed     =>  [ 'summary-button' ]
  }

  module StateDoesNotAllowTubePreviewing
    def control_tube_preview(&block)
      # Does nothing because you are not allowed to!
    end

    def control_source_view(&block)
      yield
      nil
    end

    def control_tube_view(&block)
      # Does nothing because you have no tubes
    end
    alias_method(:control_additional_printing, :control_tube_view)
  end

  state_machine :tube_state, :initial => :pending, :namespace => 'tube' do
    Presenters::Statemachine::StateTransitions.inject(self)

    state :pending do
      include StateDoesNotAllowTubePreviewing
    end
    state :started do
      include StateDoesNotAllowTubePreviewing
    end
    state :passed do
      def control_tube_preview(&block)
        yield unless plate.has_transfers_to_tubes?
        nil
      end

      def control_source_view(&block)
        yield unless plate.has_transfers_to_tubes?
        nil
      end

      def control_tube_view(&block)
        yield if plate.has_transfers_to_tubes?
        nil
      end
      alias_method(:control_additional_printing, :control_tube_view)
    end
    state :failed do
      include StateDoesNotAllowTubePreviewing
    end
    state :cancelled do
      include StateDoesNotAllowTubePreviewing
    end
  end

  def tube_state
    plate.state
  end

  def tube_state=(state)
    # Ignore this
  end
end
