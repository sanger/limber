module Presenters
  class TubePresenter
    include Presenter
    include Statemachine::Shared

    class_inheritable_reader :labware_class
    write_inheritable_attribute :labware_class, :tube

    write_inheritable_attribute :attributes, [ :api, :labware ]

    class_inheritable_reader    :additional_creation_partial
    write_inheritable_attribute :additional_creation_partial, 'labware/tube/child_tube_creation'

    class_inheritable_reader    :tab_views
    write_inheritable_attribute :tab_views, {
      'labware-summary-button'          => [ 'labware-summary', 'tube-printing' ],
      'labware-creation-button' => [ 'labware-summary', 'tube-creation' ],
      'labware-QC-button'       => [ 'labware-summary', 'tube-creation' ],
      'labware-state-button'    => [ 'labware-summary', 'tube-state' ]
    }

    class_inheritable_reader    :tab_states

    class_inheritable_reader    :authenticated_tab_states
    write_inheritable_attribute :authenticated_tab_states, {
        :pending     => [ 'labware-summary-button', 'labware-state-button' ],
        :started     => [ 'labware-state-button', 'labware-summary-button' ],
        :passed      => [ 'labware-state-button', 'labware-summary-button' ],
        :qc_complete => [ 'labware-creation-button','labware-summary-button' ],
        :cancelled   => [ 'labware-summary-button' ],
        :failed      => [ 'labware-summary-button' ]
    }

    LABEL_TEXT = 'ILB Stock'
    class_inheritable_reader    :label_text
    write_inheritable_attribute :label_text, LABEL_TEXT

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

      event :fail do
        transition [ :passed ] => :failed
      end

      event :cancel do
        transition [ :pending, :started ] => :cancelled
      end

      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :qc_complete, :human_name => 'QC Complete' do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def control_additional_creation(&block)
          yield unless default_child_purpose.nil?
          nil
        end

        # Returns the child plate purposes that can be created in the qc_complete state.
        def default_child_purpose
          purpose.children.first
        end
      end

    end

    # The state is delegated to the tube
    delegate :state, :to => :labware


    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    def purpose
      labware.purpose
    end

    def labware_form_details(view)
      { :url => view.illumina_b_tube_path(self.labware), :as => :tube }
    end

    class UnknownTubeType < StandardError
      attr_reader :tube

      def initialize(plate)
        super("Unknown plate type #{tube.purpose.name.inspect}")
        @tube = tube
      end
    end

    def self.lookup_for(labware)
      presentation_classes = Settings.purposes[labware.purpose.uuid] or raise UnknownPlateType, labware
      presentation_classes[:presenter_class].constantize
    end
  end
end
