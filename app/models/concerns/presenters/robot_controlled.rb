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

    def suitable_for_labware?(config)
      config[:beds]
        .detect { |_bed, bed_config| bed_config.purpose == purpose_name && bed_config.states.include?(labware.state) }
        .present?
    end

    def multiple_robots?
      suitable_robots.count > 1
    end
  end
end
