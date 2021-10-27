# frozen_string_literal: true

# Tube racks can be barcoded, and contain tubes at defined locations.
class Sequencescape::Api::V2::TubeRack < Sequencescape::Api::V2::Base
  include WellHelpers::Extensions

  has_one :purpose
  has_many :racked_tubes

  property :created_at, type: :time
  property :updated_at, type: :time
  property :labware_barcode, type: :barcode

  property :name
  property :size
  property :number_or_rows
  property :number_of_columns

  delegate :name, to: :purpose, allow_nil: true, prefix: true

  def barcode
    labware_barcode
  end

  def model_name
    ::ActiveModel::Name.new(Sequencescape::Api::V2::TubeRack, false, 'Limber::TubeRack')
  end

  def human_barcode
    labware_barcode.human
  end
end
