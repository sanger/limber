# frozen_string_literal: true

# A plate from sequencescape via the V2 API
class Sequencescape::Api::V2::Labware < Sequencescape::Api::V2::Base
  def self.table_name
    'labware'
  end

  property :created_at, type: :time
  property :updated_at, type: :time
  property :labware_barcode, type: :barcode

  # Not great, as only true for tubes/plates not wells
  # But until we get polymorphic association support
  has_one :purpose

  #
  # Plates and tubes are handled by different URLs. This allows us to redirect
  # to the expected endpoint.
  # @return [ActiveModel::Name] The resource behaves like a Limber::Tube/Limber::Plate
  #
  def model_name
    case type
    when 'tubes'
      ::ActiveModel::Name.new(Limber::Tube, false)
    when 'plates'
      ::ActiveModel::Name.new(Limber::Plate, false)
    else
      raise "Can't view #{type} in limber"
    end
  end

  # Currently use the uuid as our main identifier, might switch to human barcode soon
  def to_param
    uuid
  end

  def plate?
    type == 'plates'
  end

  def tube?
    type == 'tubes'
  end

  def barcode
    labware_barcode
  end
end
