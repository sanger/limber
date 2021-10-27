# frozen_string_literal: true

# Tube racks can be barcoded, and contain tubes at defined locations.
class Sequencescape::Api::V2::TubeRack < Sequencescape::Api::V2::Base
  has_one :purpose

  property :created_at, type: :time
  property :updated_at, type: :time
  property :labware_barcode, type: :barcode

  def barcode
    labware_barcode
  end
end
