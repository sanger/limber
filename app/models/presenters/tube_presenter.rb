module Presenters
  class TubePresenter
    include Presenter

    class_inheritable_reader    :tab_views
    write_inheritable_attribute :tab_views, {
      'summary-button'          => [ 'labware-summary', 'tube-printing' ],
      'labware-creation-button' => [ 'labware-summary', 'tube-creation' ],
      'labware-QC-button'       => [ 'labware-summary', 'tube-creation' ],
      'labware-state-button'    => [ 'labware-summary', 'tube-state' ]
    }

    class_inheritable_reader    :tab_states
    write_inheritable_attribute :tab_states, [
      :pending,
      :started,
      :passed,
      :qc_complete,
      :cancelled
    ].each_with_object({}) {|k,h| h[k] = ['summary-button']}

    class_inheritable_reader    :authenticated_tab_states
    write_inheritable_attribute :authenticated_tab_states, {
        :pending    =>  [ 'summary-button', 'labware-state-button' ],
        :started    =>  [ 'labware-state-button', 'summary-button' ],
        :passed     =>  [ 'labware-creation-button','summary-button', 'labware-state-button' ],
        :cancelled  =>  [ 'summary-button' ],
        :failed     =>  [ 'summary-button' ]
    }
    state_machine :state, :initial => :pending do
      Statemachine::StateTransitions.inject(self)

      state :pending do

      end
      state :started do

      end
      state :passed do

      end
      state :failed do

      end
      state :cancelled do

      end
    end

    # The state is delegated to the tube
    delegate :state, :to => :tube

    # Yields to the block if there is the possibility of controlling the state change, passing
    # the valid next states, along with the current one too.
    def control_state_change(&block)
      yield(state_transitions) if state_transitions.present?
      nil
    end

    #--
    # We ignore the assignment of the state because that is the statemachine getting in before
    # the tube has been loaded.
    #++
    def state=(value) #:nodoc:
      # Ignore this!
    end

    write_inheritable_attribute :attributes, [ :api, :tube ]

    def labware
      self.tube
    end

    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    def purpose
      labware.purpose
    end

    def labware_form_details(view)
      { :url => view.illumina_b_tube_path(self.tube), :as  => :tube }
    end
  end
end
