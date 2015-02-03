class Presenters::FinalPooledPresenter < Presenters::PooledPresenter
  include Presenters::Statemachine
  include Presenters::AlternativePooling

  write_inheritable_attribute :summary_partial, 'labware/plates/pooled_into_tubes_plate'
  write_inheritable_attribute :printing_partial, 'labware/plates/tube_printing'
  write_inheritable_attribute :robot_controlled_states, { :pending => 'nx8-post-cap-lib-pool' }
  write_inheritable_attribute :csv, 'show_pooled_alternative'

  write_inheritable_attribute :authenticated_tab_states, {
    :pending    =>  [ 'labware-summary-button', 'labware-state-button' ],
    :started    =>  [ 'labware-state-button',   'labware-summary-button' ],
    :passed     =>  [ 'labware-summary-button', 'labware-state-button'],
    :cancelled  =>  [ 'labware-summary-button' ],
    :failed     =>  [ 'labware-summary-button' ]
  }

  def has_qc_data?; true; end

  def tube_label_text
    labware.tubes.map do |tube|
      "#{tube.label.prefix} #{tube.label.text}"
    end
  end

  def default_tube_printer_uuid
    Settings.printers[location][:tube]
  end

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

      def transfers
        labware.well_to_tube_transfers
      end

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
