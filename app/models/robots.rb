# frozen_string_literal: true

# Robots carry out bed verification
# Each robot in Settings.robots is identified by a key
# and defines a particular robot program.
# Robot programs identify the type and state of the plates
# on each bed as well as relationships between them.
module Robots
  def self.find(options)
    robot_settings = Settings.robots[options[:id]]
    raise ActionController::RoutingError, "Robot #{options[:name]} Not Found" if robot_settings.nil?

    robot_class = robot_settings.fetch(:class, 'Robots::Robot').constantize
    robot_class.new(robot_settings.to_hash.merge(options))
  end

  def self.each_robot
    Settings.robots.each do |key, config|
      yield key, config[:name]
    end
  end
end
