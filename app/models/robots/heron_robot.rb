# frozen_string_literal: true

module Robots
  # TO DO: decide on name of class
  # Takes 2 pairs of plates and pools them into 2 destination plates
  # The source plates are not tracked plates, just barcodes, so the verification method has to be different
  class HeronRobot < Robot
    # might need to override valid_plates and valid_relationships
    # or, might get away with just creating a a new subclass of 'bed' for beds 1-4, to change the bed.valid? and other methods
  end
end
