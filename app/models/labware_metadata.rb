# frozen_string_literal: true

class LabwareMetadata # rubocop:todo Style/Documentation
  attr_accessor :user_uuid, :labware, :barcode

  def initialize(params = {})
    # Initialize with either a barcode or a labware object
    # If both are given, the labware is used
    # If neither is given, an ArgumentError is raised
    # If a barcode is given, but no labware is found, a JsonApiClient::Errors::NotFound is raised
    @user_uuid = params.fetch(:user_uuid, nil)
    @labware = params.fetch(:labware, nil)
    @barcode = params.fetch(:barcode, nil)

    raise ArgumentError, 'Parameters labware or barcode missing' if @barcode.nil? && @labware.nil?

    @user = Sequencescape::Api::V2::User.find(uuid: @user_uuid).first unless @user_uuid.nil?
    @labware ||= Sequencescape::Api::V2::Labware.find!(barcode:).first
  end

  def update!(metadata)
    if @labware.custom_metadatum_collection&.uuid.present?
      current_metadata = self.metadata.symbolize_keys
      @labware.custom_metadatum_collection.update!(metadata: current_metadata.merge(metadata.symbolize_keys))
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
