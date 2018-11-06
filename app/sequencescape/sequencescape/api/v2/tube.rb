# frozen_string_literal: true

# Tubes can be barcoded, but only have one receptacle for samples.
class Sequencescape::Api::V2::Tube < Sequencescape::Api::V2::Base
  self.tube = true

  property :created_at, type: :time
  property :updated_at, type: :time
  property :labware_barcode, type: :barcode

  has_one :purpose

  def barcode
    labware_barcode
  end
end
