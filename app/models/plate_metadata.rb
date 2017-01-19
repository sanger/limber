class PlateMetadata

  include ActiveModel::Model

  attr_accessor :plate, :api, :created_with_robot, :user

  validates_presence_of :api, :plate, :user

  def initialize(attributes={})
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
    unless plate.custom_metadatum_collection.uuid.present?
      api.custom_metadatum_collection.create!(user: user, asset: plate.uuid, metadata: {created_with_robot: created_with_robot})
    else
      metadata = plate.custom_metadatum_collection.metadata
      plate.custom_metadatum_collection.update_attributes!(metadata: metadata.merge(created_with_robot: created_with_robot))
    end
  end

private

  def find_plate(plate_barcode)
    begin
      @plate = api.search.find(Settings.searches['Find assets by barcode']).first(barcode: plate_barcode)
    rescue Sequencescape::Api::ResourceNotFound
    end
  end

end