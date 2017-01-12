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
  end

private

  def find_plate(plate_barcode)
    begin
      @plate = api.search.find(Settings.searches['Find assets by barcode']).first(barcode: plate_barcode)
    rescue Sequencescape::Api::ResourceNotFound
    end
  end

end