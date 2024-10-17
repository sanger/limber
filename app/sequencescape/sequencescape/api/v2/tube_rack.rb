# frozen_string_literal: true

# Tube racks can be barcoded, and contain tubes at defined locations.
class Sequencescape::Api::V2::TubeRack < Sequencescape::Api::V2::Base
  include WellHelpers::Extensions
  include Sequencescape::Api::V2::Shared::HasPurpose
  include Sequencescape::Api::V2::Shared::HasBarcode
  include Sequencescape::Api::V2::Shared::HasPolyMetadata

  has_many :racked_tubes
  has_many :ancestors, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :descendants, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :children, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class

  property :created_at, type: :time
  property :updated_at, type: :time

  property :name
  property :size
  property :number_or_rows
  property :number_of_columns
  property :tuberack_barcode

  def model_name
    ::ActiveModel::Name.new(Sequencescape::Api::V2::TubeRack, false, 'Limber::TubeRack')
  end
end
