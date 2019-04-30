# frozen_string_literal: true

class PlateMetadata
  include ActiveModel::Model

  attr_accessor :api, :user, :plate, :barcode

  validates :api, :user, :plate, presence: true

  def initialize(params = {})
    super
    if barcode.present?
      @plate = find_plate(barcode, api)
    end
  end

  def update!(metadata)
    if plate.custom_metadatum_collection.uuid.present?
      current_metadata = plate.custom_metadatum_collection.metadata
      plate.custom_metadatum_collection.update!(metadata: current_metadata.merge(metadata))
    else
      api.custom_metadatum_collection.create!(user: user, asset: plate.uuid, metadata: metadata)
    end
  end

  def metadata
    @plate.custom_metadatum_collection.metadata
  end

  private

  def find_plate(plate_barcode, api)
    api.search.find(Settings.searches['Find assets by barcode']).first(barcode: plate_barcode)
  end
end
