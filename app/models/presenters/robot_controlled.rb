# frozen_string_literal: true
module Presenters
  module RobotControlled
    def each_robot
      suitable_robots.each { |key, config| yield(key, config[:name]) }
    end

    def robot_exists?
      suitable_robots.present?
    end

    def statechange_link(view)
      case suitable_robots.count
      when 0
        '#'
      when 1
        view.robot_path(suitable_robots.keys.first)
      else
        '#popupRobots'
      end
    end

    def statechange_label
      robot_exists? ? 'Bed verification' : default_statechange_label
    end

    def if_statechange_active(content)
      robot_exists? ? '' : content
    end

    def statechange_attributes
      multiple_robots? ? 'data-rel="popup" data-inline="true" data-transition="flip"'.html_safe : ''
    end

    private

    def suitable_robots
      @suitable_robots ||= Settings.robots.select { |_key, config| suitable_for_labware?(config) }
    end

    def suitable_for_labware?(config)
      config.beds.detect do |_bed, bed_config|
        # We only want to detect target plates, otherwise we stop eg. manual failures
        bed_config.target_state.present? &&
          bed_config.purpose == purpose.name && bed_config.states.include?(labware.state)
      end.present?
    end

    def multiple_robots?
      suitable_robots.count > 1
    end
  end
end
