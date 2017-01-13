class PlateMetadata

  include ActiveModel::Model

  attr_accessor :plate, :api, :robot_barcode, :user

  validates_presence_of :api, :plate, :user

  def initialize(attributes={})
    super
  end

  def plate=(plate_barcode)
    return unless plate_barcode.present?
    find_plate(plate_barcode)
  end

  def update
    unless plate.custom_metadatum_collection.uuid.present?
      api.custom_metadatum_collection.create!(user: user, asset: plate.uuid, metadata: {robot_barcode: robot_barcode})
    else
      metadata = plate.custom_metadatum_collection.metadata
      plate.custom_metadatum_collection.update_attributes!(metadata: metadata.merge(robot_barcode: robot_barcode))
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