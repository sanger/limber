# frozen_string_literal: true

# A labware from sequencescape via the V2 API
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

  has_many :state_changes
  has_many :ancestors, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class

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

  def input_barcode
    useful_barcode(stock_plate.try(:barcode))
  end

  # for figuring out input plate barcode
  def stock_plates(purpose_names: SearchHelper.stock_plate_names)
    @stock_plates ||= stock_plate? ? [self] : ancestors.select{ |a| purpose_names.include? a.purpose.name }
  end

  def stock_plate
    return self if stock_plate?

    stock_plates.sort { |a, b| b.id <=> a.id }.first
  end

  def stock_plate?(purpose_names: SearchHelper.stock_plate_names)
    purpose_names.include?(purpose.name)
  end

  def useful_barcode(barcode)
    return 'Unknown' if barcode.nil?

    # Support for old API
    human_readable = barcode.try(:human) || "#{barcode.prefix}#{barcode.number}"

    if human_readable == barcode.machine
      human_readable
    else
      "#{human_readable} <em>#{barcode.machine}</em>".html_safe # rubocop:todo Rails/OutputSafety
    end
  end
end
