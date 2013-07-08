class Presenters::PcrXpPresenter < Presenters::PooledPresenter
  include Presenters::Statemachine::QcCompletable

  write_inheritable_attribute :summary_partial, 'labware/plates/pooled_into_tubes_plate'
  write_inheritable_attribute :printing_partial, 'labware/plates/tube_printing'

  write_inheritable_attribute :authenticated_tab_states, {
    :pending     => [ 'labware-summary-button', 'robot-verification-button' ],
    :started     => [ 'labware-state-button', 'labware-summary-button' ],
    :passed      => [ 'labware-state-button', 'labware-summary-button', 'well-failing-button', 'labware-creation-button' ],
    :qc_complete => [ 'labware-summary-button', 'labware-state-button' ],
    :cancelled   => [ 'labware-summary-button' ],
    :failed      => [ 'labware-summary-button' ]
  }

  write_inheritable_attribute :robot_name, 'nx-96'

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
      def has_qc_data?; true; end
      include QcCreatableStep
    end

    state :qc_complete do
      def has_qc_data?; true; end
      def allow_plate_label_printing?; false end

      def tube_label_text
        labware.tubes.map do |tube|
          "#{tube.label.prefix} #{tube.label.text}"
        end
      end

      # Don't yield in :qc_complete state
      def control_source_view(&block)
        yield unless labware.has_transfers_to_tubes?
        nil
      end

      # Yield tube view in :qc_complete state
      def control_tube_view(&block)
        yield if labware.has_transfers_to_tubes?
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

  def default_tube_printer_uuid
    Settings.printers[location][Settings.purposes[default_child_purpose.uuid].default_printer_type]
  end

  def tube_state=(state)
    # Ignore this
  end
end
