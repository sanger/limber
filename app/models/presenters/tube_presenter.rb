module Presenters
  class TubePresenter
    include Presenter

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
    # the plate has been loaded.
    #++
    def state=(value) #:nodoc:
      # Ignore this!
    end

    write_inheritable_attribute :attributes, [ :api, :tube ]

    def lab_ware
      self.tube
    end

    def lab_ware_form_details(view)
      { :url => view.illumina_b_multiplexed_library_tube_path(self.tube), :as  => :tube }
    end
  end
end
