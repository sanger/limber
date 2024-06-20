# frozen_string_literal: true

module Presenters::Statemachine
  # This module provides a method to determine if a feature can be enabled
  # based on the current state of the instance.
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

        includes, excludes = parse_states(states)

        # Exludes take precedence over includes.
        return false if excludes.present? && excludes.include?(current_state)

        # If includes is present, the current state must be in the list.
        includes.present? ? includes.include?(current_state) : default
      end

      private

      # Parses the states parameter into includes and excludes arrays.
      #
      # @param states [String, Symbol, Array, Hash] The states to check against.
      # @return [Array] Returns an array with two elements: includes and excludes.
      #
      # :reek:TooManyStatements
      def parse_states(states)
        case states
        when Hash
          states = states.stringify_keys
          includes = parse_tokens(states['includes'])
          excludes = parse_tokens(states['excludes'])
        else
          includes = parse_tokens(states)
          excludes = []
        end
        [includes, excludes]
      end

      # Parses the state name tokens into an array of strings.
      #
      # @param tokens [String, Symbol, Array] The tokens to parse.
      # @return [Array] Returns an array of strings.
      #
      # :reek:UtilityFunction { public_methods_only: true}
      def parse_tokens(tokens)
        case tokens
        when String, Symbol
          [tokens.to_s] # single
        when Array
          tokens.map(&:to_s) # multiple
        else
          [] # none
        end
      end
    end
  end
end
