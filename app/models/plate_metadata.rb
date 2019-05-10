# frozen_string_literal: true

class PlateMetadata
  attr_accessor :api, :user, :plate, :barcode

  def initialize(params = {})
    @api = params.fetch(:api, nil)
    @user = params.fetch(:user, nil)
    @barcode = params.fetch(:barcode, nil)
    if barcode.present?
      @plate = find_plate(barcode, api)
    else
      @plate = params.fetch(:plate, nil)
      raise ArgumentError, 'Parameters plate or barcode missing' if plate.nil?
    end
    raise ArgumentError, 'Parameter api missing' unless api.present?
  end

  def update!(metadata)
    if plate.custom_metadatum_collection.uuid.present?
      current_metadata = plate.custom_metadatum_collection.metadata.symbolize_keys
      plate.custom_metadatum_collection.update!(
        metadata: current_metadata.merge(metadata.symbolize_keys)
      )
    else
      api.custom_metadatum_collection.create!(
        user: user, asset: plate.uuid, metadata: metadata.symbolize_keys
      )
    end
  end

  def metadata
    @plate.custom_metadatum_collection.metadata
  rescue URI::InvalidURIError
    nil
  end

  private

  def find_plate(plate_barcode, api)
    api.search.find(Settings.searches['Find assets by barcode']).first(barcode: plate_barcode)
  end
end
