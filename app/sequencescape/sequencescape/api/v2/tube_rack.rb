# frozen_string_literal: true

# Tube racks can be barcoded, and contain tubes at defined locations.
class Sequencescape::Api::V2::TubeRack < Sequencescape::Api::V2::Base
  include WellHelpers::Extensions
  include Sequencescape::Api::V2::Shared::HasPurpose
  include Sequencescape::Api::V2::Shared::HasBarcode

  has_many :racked_tubes

  property :created_at, type: :time
  property :updated_at, type: :time

  property :name
  property :size
  property :number_or_rows
  property :number_of_columns

  # Other relationships
  # has_one :purpose via Sequencescape::Api::V2::Shared::HasPurpose

  def model_name
    ::ActiveModel::Name.new(Sequencescape::Api::V2::TubeRack, false, 'TubeRack')
  end
end
