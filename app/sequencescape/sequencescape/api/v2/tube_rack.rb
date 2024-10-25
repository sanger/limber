# frozen_string_literal: true

# Tube racks can be barcoded, and contain racked tubes at defined locations.
class Sequencescape::Api::V2::TubeRack < Sequencescape::Api::V2::Base
  include WellHelpers::Extensions
  include Sequencescape::Api::V2::Shared::HasPurpose
  include Sequencescape::Api::V2::Shared::HasBarcode
  include Sequencescape::Api::V2::Shared::HasPolyMetadata

  self.tube_rack = true

  # This is needed in order for the URL helpers to work correctly
  def to_param
    uuid
  end

  #
  # Override the model used in form/URL helpers
  # to allow us to treat old and new api the same
  #
  # @return [ActiveModel::Name] The resource behaves like a Limber::TubeRack
  #
  def model_name
    ::ActiveModel::Name.new(Limber::TubeRack, false)
  end

  has_many :racked_tubes, class_name: 'Sequencescape::Api::V2::RackedTube'
  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class

  property :name
  property :size
  property :number_or_rows
  property :number_of_columns
  property :tuberack_barcode

  property :created_at, type: :time
  property :updated_at, type: :time

  def stock_plate
    nil
  end
end
