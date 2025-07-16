# frozen_string_literal: true

module Presenters
  module RobotControlled # rubocop:todo Style/Documentation
    def each_robot
      suitable_robots.each { |key, config| yield(key, config[:name]) }
    end

    def robot?
      suitable_robots.present?
    end

    private

    def suitable_robots
      @suitable_robots ||= Settings.robots.select { |_key, config| suitable_for_labware?(config) }
    end

    # Determines whether the given robot configuration is suitable for the current labware.
    #
    # If any beds in the configuration have a `parent` property, it checks whether any of those
    # robots match the required purpose and include the current labware state. This ensures that
    # the robot is used in the correct context — after the labware has been created.
    #
    # If no parent properties are found, it falls back to checking whether any bed in the configuration
    # matches the required purpose and includes the current labware state.
    #
    # @param config [Hash, Hashie::Mash] The robot configuration to evaluate.
    # @return [Boolean, Hash, Hashie::Mash, nil] Returns the matching robot object or `true`/`false`
    #   depending on the evaluation branch. Returns `nil` if no match is found.
    def suitable_for_labware?(config)
      robots_with_parents = find_robots_with_parent_property(config.beds)
      robots_with_parents.present? ? match_robot_with_parent(robots_with_parents) : bed_suitable_for_labware?(config)
    end

    def match_robot_with_parent(robots_with_parents)
      robots_with_parents.detect { |robot| robot.purpose == purpose_name && robot.states.include?(labware.state) }
    end

    def bed_suitable_for_labware?(config)
      config
        .beds
        .detect { |_bed, bed_config| bed_config.purpose == purpose_name && bed_config.states.include?(labware.state) }
        .present?
    end

    # Finds all immediate nested hashes (or Hashie::Mash objects) within the given object
    # that contain a `parent` key.
    # @param obj [Hash, Hashie::Mash] The object to search through.
    #   Example input:
    #   {
    #     robot-1: {
    #        label: bed-1,
    #        purpose: 'purpose 1',
    #        states: ['state x'],
    #     }
    #     robot-2: {
    #        label: bed-2,
    #        purpose: 'purpose 2',
    #        states: ['state y'],
    #        parent: 'robot-1'
    #     }
    #  }
    #
    # @return [Array<Hash, Hashie::Mash>] An array of immediate values that contain a `parent` key.
    #   Example return value:
    #     [
    #       { label: bed-2, purpose: 'purpose 2', states: ['state y'], parent: 'robot-1' }
    #     ]
    def find_robots_with_parent_property(obj)
      return [] unless obj.is_a?(Hash) || obj.is_a?(Hashie::Mash)
      obj.values.select { |value| (value.is_a?(Hash) || value.is_a?(Hashie::Mash)) && value.key?('parent') }
    end

    def multiple_robots?
      suitable_robots.count > 1
    end
  end
end
