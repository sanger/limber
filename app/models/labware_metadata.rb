# frozen_string_literal: true

class LabwareMetadata # rubocop:todo Style/Documentation
  attr_accessor :user_uuid, :labware, :barcode

  def initialize(params = {})
    @user_uuid = params.fetch(:user_uuid, nil)
    @user = Sequencescape::Api::V2::User.find(uuid: @user_uuid).first unless @user_uuid.nil?
    @barcode = params.fetch(:barcode, nil)
    if barcode.present?
      @labware = Sequencescape::Api::V2::Labware.find(barcode: barcode).first
    else
      @labware = params.fetch(:labware, nil)
      raise ArgumentError, 'Parameters labware or barcode missing' if labware.nil?
    end
  end

  def update!(metadata)
    if @labware.custom_metadatum_collection&.uuid.present?
      current_metadata = self.metadata.symbolize_keys
      labware.custom_metadatum_collection.update!(metadata: current_metadata.merge(metadata.symbolize_keys))
    else
      Sequencescape::Api::V2::CustomMetadatumCollection.create!(
        user_id: @user&.id,
        asset_id: @labware.id,
        metadata: metadata.symbolize_keys
      )
    end
  end

  def metadata
    # Note that not all labware has custom metadata, hence the null-coalescing operator for the metadata method
    @labware.custom_metadatum_collection&.metadata
  end
end
