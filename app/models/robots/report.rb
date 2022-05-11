# frozen_string_literal: true

module Robots
  # Simple report object packaged up for easy json rendering and testing
  Report = Struct.new(:beds, :valid, :message) { alias_method :valid?, :valid }
end
