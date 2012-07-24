module Presenters::Statemachine
  module StateDoesNotAllowChildCreation
    def control_child_plate_creation(&block)
      # Does nothing because you can't!
    end
    alias_method(:control_additional_creation, :control_child_plate_creation)
  end

  # These are shared base methods to be used in all presenter state_machines
  module Shared
    #--
    # We ignore the assignment of the state because that is the statemachine getting in before
    # the plate has been loaded.
    #++
    def state=(value) #:nodoc:
      # Ignore this!
    end

    # Yields to the block if there is the possibility of controlling the state change, passing
    # the valid next states, along with the current one too.
    def control_state_change(&block)
      # Look for a default transition
      default_transition = state_transitions.detect {|t| t.event == :take_default_path }

      if default_transition.present?
        # This ugly thing should yield the default transition first followed by
        # any other transitions to states that aren't the default...
        yield( [default_transition] + state_transitions.reject {|t| t.to == default_transition.to } )
      elsif state_transitions.present?
        # ...if there's no default transition but there are still other transitions
        # present then yield those.
        yield(state_transitions)
      end

      nil
    end

    # Does nothing
    def control_additional_printing(&block)
    end

    def all_plate_states
      self.class.state_machines[:state].states.map(&:value)
    end
  end

  # State transitions are common across all of the statemachines.
  module StateTransitions #:nodoc:
    def self.inject(base)
      base.instance_eval do

        event :take_default_path do
          transition :pending => :started
          transition :started => :passed
        end

        event :start do
          transition :pending => :started
        end
        event :pass do
          transition [ :pending, :started ] => :passed
        end
        event :fail do
          transition [ :pending, :started ] => :failed
        end
        event :cancel do
          transition [ :pending, :started, :passed, :failed ] => :cancelled
        end
      end
    end
  end

  def self.included(base)
    base.class_eval do
      include Shared

      # The state machine for plates which has knock-on effects on the plates that can be created
      state_machine :state, :initial => :pending do
        StateTransitions.inject(self)

        # These are the states, which are really the only things we need ...
        state :pending do
          include StateDoesNotAllowChildCreation
        end

        state :started do
          include StateDoesNotAllowChildCreation
        end

        state :passed do
          # Yields to the block if there are child plates that can be created from the current one.
          # It passes the valid child plate purposes to the block.
          def control_additional_creation(&block)
            yield unless child_plate_purposes.empty?
            nil
          end

          # Returns the child plate purposes that can be created in the passed state.  Typically
          # this is only one, but it specifically excludes QC plates.
          def child_plate_purposes
            # plate.plate_purpose.children.reject { |p| p.name == 'Pulldown QC plate' }
            plate.plate_purpose.children
          end
        end
        state :failed do
          include StateDoesNotAllowChildCreation
        end
        state :cancelled do
          include StateDoesNotAllowChildCreation
        end
      end

      # The current state of the plate is delegated to the plate
      delegate :state, :to => :plate
    end
  end


end
