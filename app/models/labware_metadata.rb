# frozen_string_literal: true

class LabwareMetadata # rubocop:todo Style/Documentation
  attr_accessor :api, :user, :labware, :barcode

  def initialize(params = {})
    @api = params.fetch(:api, nil)
    @user = params.fetch(:user, nil)
    @barcode = params.fetch(:barcode, nil)
    if barcode.present?
      @labware = find_labware(barcode, api)
    else
      @labware = params.fetch(:labware, nil)
      raise ArgumentError, 'Parameters labware or barcode missing' if labware.nil?
    end
    raise ArgumentError, 'Parameter api missing' if api.nil?
  end

  def update!(metadata) # rubocop:todo Metrics/AbcSize
    if labware.custom_metadatum_collection.uuid.present?
      current_metadata = labware.custom_metadatum_collection.metadata.symbolize_keys
      labware.custom_metadatum_collection.update!(
        metadata: current_metadata.merge(metadata.symbolize_keys)
      )
    else
      api.custom_metadatum_collection.create!(
        user: user, asset: labware.uuid, metadata: metadata.symbolize_keys
      )
    end
  end

  def metadata
    @labware.custom_metadatum_collection.metadata
  rescue URI::InvalidURIError
    nil
  end

  private

  def find_labware(labware_barcode, api)
    api.search.find(Settings.searches['Find assets by barcode']).first(barcode: labware_barcode)
  end
end
