# frozen_string_literal: true

module Robots
  def self.find(options)
    robot_settings = Settings.robots[options[:id]]
    raise ActionController::RoutingError, "Robot #{options[:name]} Not Found" if robot_settings.nil?
    robot_class = (robot_settings[:class] || 'Robots::Robot').constantize
    robot_class.new(robot_settings.merge(options))
  end

  def self.each_robot
    Settings.robots.each do |key, config|
      yield key, config[:name]
    end
  end
end
