module Presenters
  class FinalTubePresenter
    include Presenter
    include Statemachine::Shared

    def location
      # TODO: Consider adding location to tube api as well
      :illumina_b
    end

    class_inheritable_reader :labware_class
    write_inheritable_attribute :labware_class, :tube

    write_inheritable_attribute :attributes, [ :api, :labware ]

    class_inheritable_reader    :additional_creation_partial
    write_inheritable_attribute :additional_creation_partial, nil

    class_inheritable_reader    :tab_views
    write_inheritable_attribute :tab_views, {
      'labware-summary-button'  => [ 'labware-summary', 'tube-printing' ],
      'labware-creation-button' => [ 'labware-summary', 'tube-creation' ],
      'labware-state-button'    => [ 'labware-summary', 'tube-state' ]
    }

    class_inheritable_reader    :tab_states

    class_inheritable_reader    :authenticated_tab_states
    write_inheritable_attribute :authenticated_tab_states, {
        :pending     => [ 'labware-summary-button', 'labware-state-button' ],
        :started     => [ 'labware-summary-button', 'labware-state-button' ],
        :passed      => [ 'labware-summary-button', 'labware-state-button' ],
        :qc_complete => [ 'labware-summary-button' ],
        :cancelled   => [ 'labware-summary-button' ],
        :failed      => [ 'labware-summary-button' ]
    }

    state_machine :state, :initial => :pending do
      event :start do
        transition :pending => :started
      end

      event :take_default_path do
        transition :pending => :started
        transition :started => :passed
      end

      event :pass do
        transition [ :pending, :started ] => :passed
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
        def has_qc_data?; true; end
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :qc_complete, :human_name => 'QC Complete' do
        def has_qc_data?; true; end
        include Statemachine::StateDoesNotAllowChildCreation
      end

      event :qc_complete do
        transition :passed => :qc_complete
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

    def label_text
      "#{labware.label.prefix} #{labware.label.text|| LABEL_TEXT}"
    end

    def labware_form_details(view)
      { :url => view.illumina_b_tube_path(self.labware), :as => :tube }
    end

    def qc_owner
      labware
    end
  end
end
