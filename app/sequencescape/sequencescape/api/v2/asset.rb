# frozen_string_literal: true

# Hopefully temporary class to handle limitations in json-api-client in handling
# polymorphic associations
# Note: [JG] 20181003 I actually appear to be hitting the correct class
# now, but am not sure what changed.
class Sequencescape::Api::V2::Asset < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasQcFiles

  property :created_at, type: :time
  property :updated_at, type: :time
  property :labware_barcode, type: :barcode

  # Not great, as only true for tubes/plates not wells
  # But until we get polymorphic association support
  has_one :purpose

  def plate?
    type == 'plates'
  end

  def tube?
    type == 'tubes'
  end

  def tube_rack?
    type == 'tube_racks'
  end

  def barcode
    labware_barcode
  end
end
