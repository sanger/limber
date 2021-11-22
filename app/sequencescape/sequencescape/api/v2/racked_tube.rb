# frozen_string_literal: true

# Tube racks can be barcoded, and contain tubes at defined locations.
class Sequencescape::Api::V2::RackedTube < Sequencescape::Api::V2::Base
  has_one :tube
  has_one :tube_rack

  property :coordinate
end
