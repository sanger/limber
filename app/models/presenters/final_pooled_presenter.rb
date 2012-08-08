class Presenters::FinalPooledPresenter < Presenters::PooledPresenter
  write_inheritable_attribute :summary_partial, 'labware/plates/pooled_into_tubes_plate'
  write_inheritable_attribute :printing_partial, 'labware/plates/tube_printing'

  write_inheritable_attribute :authenticated_tab_states, {
    :pending    =>  [ 'labware-summary-button', 'labware-state-button' ],
    :started    =>  [ 'labware-summary-button', 'labware-state-button' ],
    :passed     =>  [ 'labware-summary-button', 'labware-state-button' ],
    :cancelled  =>  [ 'labware-summary-button' ],
    :failed     =>  [ 'labware-summary-button' ]
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
