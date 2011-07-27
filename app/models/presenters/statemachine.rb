module Presenters::Statemachine
  module StateDoesNotAllowChildCreation
    def control_child_plate_creation(&block)
      # Does nothing because you can't!
    end
    alias_method(:control_additional_creation, :control_child_plate_creation)
  end

  # State transitions are common across all of the statemachines.
  module StateTransitions #:nodoc:
    def self.inject(base)
      base.instance_eval do
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
      # The state machine for plates which has knock-on effects on the plates that can be created
      state_machine :state, :initial => :pending do
        StateTransitions.inject(self)

        # These are the states, which are really the only things we need ...
        state :pending do
          include StateDoesNotAllowChildCreation
        end
        state :started do
          include StateDoesNotAllowChildCreation

          # Yields to the block if there are child plates that can be created from the current one.
          # It passes the valid child plate purposes to the block.
          def control_additional_creation(&block)
            yield unless child_plate_purposes.empty?
            nil
          end

          # Returns the child plate purposes that can be created in the started state.  Typically
          # this should be empty, unless QC plates can be created from the current plate.
          def child_plate_purposes
            plate.plate_purpose.children.reject { |p| p.name != 'Pulldown QC plate' }
          end
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
            plate.plate_purpose.children.reject { |p| p.name == 'Pulldown QC plate' }
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

  # Yields to the block if there is the possibility of controlling the state change, passing
  # the valid next states, along with the current one too.
  def control_state_change(&block)
    valid_next_states = state_transitions.map(&:to)
    yield(valid_next_states) unless valid_next_states.empty?
    nil
  end

  # Does nothing
  def control_additional_printing(&block)

  end

  def all_plate_states
    self.class.state_machines[:state].states.map(&:value)
  end

  #--
  # We ignore the assignment of the state because that is the statemachine getting in before
  # the plate has been loaded.
  #++
  def state=(value) #:nodoc:
    # Ignore this!
  end
end
