# frozen_string_literal: true

module Presenters::Statemachine
  # These are shared base methods to be used in all presenter state_machines
  module Shared
    extend ActiveSupport::Concern

    included do
      # Determines the scope to use when looking up state transitions
      class_attribute :state_transition_name_scope
      self.state_transition_name_scope = :default
    end

    #--
    # We ignore the assignment of the state because that is the statemachine getting in before
    # the plate has been loaded.
    #++
    def state=(value) # :nodoc:
      # Ignore this!
    end

    def default_transition
      state_transitions.detect { |t| t.event == :take_default_path }
    end

    # Yields to the block if there is the possibility of controlling the state change, passing
    # the valid next states, along with the current one too.
    def control_state_change
      if default_transition.present?
        yield(state_transitions.reject { |t| t.to == default_transition.to })
      elsif state_transitions.present?
        yield(state_transitions)
      end
    end

    def default_state_change
      yield default_transition unless default_transition.nil?
    end

    def all_plate_states
      self.class.state_machines[:state].states.map(&:value)
    end

    def state
      labware.try(:state)
    end
  end
end
