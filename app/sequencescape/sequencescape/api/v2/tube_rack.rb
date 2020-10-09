# frozen_string_literal: true

# Hopefully temporary class to handle limitations in json-api-client in handling
# polymorphic associations
# Note: [JG] 20181003 I actually appear to be hitting the correct class
# now, but am not sure what changed.
class Sequencescape::Api::V2::TubeRack < Sequencescape::Api::V2::Base
  property :created_at, type: :time
  property :updated_at, type: :time
  property :labware_barcode, type: :barcode

  def barcode
    labware_barcode
  end
end
