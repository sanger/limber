class Presenters::PcrXpPresenter < Presenters::PooledPresenter
  include Presenters::Statemachine::QcCompletable

  write_inheritable_attribute :summary_partial, 'labware/plates/pooled_into_tubes_plate'
  write_inheritable_attribute :printing_partial, 'labware/plates/tube_printing'

  write_inheritable_attribute :authenticated_tab_states, {
    :pending     => [ 'labware-summary-button', 'labware-state-button' ],
    :started     => [ 'labware-state-button', 'labware-summary-button' ],
    :passed      => [ 'labware-state-button', 'labware-summary-button', 'well-failing-button' ],
    :qc_complete => [ 'labware-summary-button', 'labware-state-button' ],
    :cancelled   => [ 'labware-summary-button' ],
    :failed      => [ 'labware-summary-button' ]
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

    def transfers
      # Does nothing because you have no tubes
    end
  end

  state_machine :tube_state, :initial => :pending, :namespace => 'tube' do

    state :pending do
      include StateDoesNotAllowTubePreviewing
    end

    state :started do
      include StateDoesNotAllowTubePreviewing
    end

    state :passed do
      include StateDoesNotAllowTubePreviewing
    end

    state :qc_complete do
      def allow_plate_label_printing?; false end

      def label_text
       Presenters::TubePresenter::LABEL_TEXT
      end

      # Don't yield in :qc_complete state
      def control_source_view(&block)
      end

      # Yield tube view in :qc_complete state
      def control_tube_view(&block)
        yield
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
    labware.state
  end

  def tube_state=(state)
    # Ignore this
  end
end
