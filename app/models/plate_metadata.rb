# frozen_string_literal: true

class PlateMetadata
  include ActiveModel::Model

  attr_reader :plate
  attr_accessor :api, :created_with_robot, :user

  validates :api, :plate, :user, presence: true

  def initialize(attributes = {})
    super
  end

  def plate=(plate)
    if plate.is_a? Sequencescape::Plate
      @plate = plate
    else
      find_plate(plate)
    end
  end

  def update
    if plate.custom_metadatum_collection.uuid.present?
      metadata = plate.custom_metadatum_collection.metadata
      plate.custom_metadatum_collection.update_attributes!(metadata: metadata.merge(created_with_robot: created_with_robot))
    else
      api.custom_metadatum_collection.create!(user: user, asset: plate.uuid, metadata: { created_with_robot: created_with_robot })
    end
  end

  private

  def find_plate(plate_barcode)
    @plate = api.search.find(Settings.searches['Find assets by barcode']).first(barcode: plate_barcode)
  rescue Sequencescape::Api::ResourceNotFound
    @plate = nil
  end
end
