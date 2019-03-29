# frozen_string_literal: true

module Robots
  # Quadrant robots take up to four parent plates which
  # are numbered according to their quadrant.
  # eg. A1 => 1, B1 => 2, A1 => 3, B2 => 4
  # While the pooling robot will work for the majority of cases,
  # it exhibits incorrect behaviour if Well A1 is missing on any
  # of the source wells.
  class QuadrantRobot < PoolingRobot
    def well_order
      :quadrant_index
    end
  end
end
