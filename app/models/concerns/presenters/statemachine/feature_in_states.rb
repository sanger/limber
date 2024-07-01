# frozen_string_literal: true

module Presenters::Statemachine
  # This module provides a method to determine if a feature can be enabled
  # based on the current state of the instance.
  #
  # State names:
  # Presenters::StandardPresenter.state_machines[:state].states.map(&:value)
  # pending, passed, started, cancelled, failed, processed_1, processed_2,
  # processed_3, processed_4, qc_complete, unknown
  module FeatureInStates
    extend ActiveSupport::Concern

    included do
      # Determines if a feature can be enabled based on provided states.
      #
      # @param states [String, Symbol, Array, Hash] The states to check against.
      # This can be a single state as a String or Symbol, an Array of states,
      # or a Hash with includes and excludes keys for states.
      # @param default [Boolean] The default return value if no specific
      # condition is met.
      # @return [Boolean] Returns true if the feature can be enabled based on
      # the states parameter, otherwise returns the default.
      #
      # :reek:BooleanParameter
      # :reek:ManualDispatch
      # :reek:TooManyStatements
      def can_be_enabled?(states, default: true)
        return default unless respond_to?(:state) # No state method.
        return default if states.blank? # No states to check.

        current_state = state.to_s
        return default if current_state.blank? # No current state.

        includes, excludes = collect_includes_and_excludes(states)

        # Excludes take precedence over includes.
        return false if excludes.present? && excludes.include?(current_state)

        # If includes is present, the current state must be in the list.
        return includes.include?(current_state) if includes.present?

        default # No specific condition met.
      end

      private

      # Returns two arrays from the states parameter: includes and excludes.
      #
      # @param states [String, Symbol, Array, Hash] The states to check against.
      # @return [Array<Array<String>] An array with two elements: includes and excludes.
      #
      # :reek:TooManyStatements
      def collect_includes_and_excludes(states)
        case states
        when Hash
          # states:
          #  includes: ...
          #  excludes: ...
          states = states.stringify_keys
          includes = collect_state_names(states['includes'])
          excludes = collect_state_names(states['excludes'])
        else
          # states: ...
          includes = collect_state_names(states)
          excludes = []
        end
        [includes, excludes]
      end

      # Returns state names as an array of strings. This method accepts a
      # symbol, a string, or an array value and returns state names. It
      # returns names for the following cases:
      # * states: ...
      #   Only the included states are specified.
      # * includes: ...
      #   Included states are specified under states separately.
      # * excludes: ...
      #   Excluded states are specified under states separately.
      # * No states
      #   An empty array is returned.
      # @param value [String, Symbol, Array] A state name or an array of state names.
      # @return [Array] State names as an array of strings.
      #
      # :reek:UtilityFunction { public_methods_only: true}
      def collect_state_names(value)
        case value
        when String, Symbol
          [value.to_s] # single state
        when Array
          value.map(&:to_s) # multiple states
        else
          [] # none
        end
      end
    end
  end
end
