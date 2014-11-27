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

  def prioritized_name(str, max_size)
    # Regular expression to match
    match = str.match(/(DN)(\d+)([[:alpha:]])( )(\w+)(:)(\w+)/)

    # Sets the priorities position matches in the regular expression to dump into the final string. They will be
    # performed with preference on the most right characters from the original match string
    priorities = [7,5,2,6,3,1,4]

    # Builds the final string by adding the matching string using the previous priorities list
    priorities.reduce([]) do |cad_list, value|
      size_to_copy = (max_size) - cad_list.join("").length
      text_to_copy = match[value]
      cad_list[value] = (text_to_copy[[0, text_to_copy.length-size_to_copy].max, size_to_copy])
      cad_list
    end.join("")
  end

  def get_tube_barcodes
    plate.tubes.map do |tube|
      tube.barcode.class.module_eval { attr_accessor :study}
      tube.barcode.class.module_eval { attr_accessor :suffix}
      tube.barcode.study = prioritized_name(tube.name, 10)
      tube.barcode
    end
  end

end
