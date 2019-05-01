# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlateMetadata do
  include FeatureHelpers

  describe 'with api' do
    let(:user_uuid)           { SecureRandom.uuid }
    let(:user)                { json :v1_user, uuid: user_uuid }
    let(:plate_uuid)          { SecureRandom.uuid }
    let(:plate)               { json :stock_plate, uuid: plate_uuid }
    let(:plate_with_metadata) { json :stock_plate_with_metadata, uuid: plate_uuid }

    has_a_working_api

    it 'is valid with a valid barcode and user' do
      stub_asset_search(123, plate)
      expect(PlateMetadata.new(api: api, barcode: 123, user: user_uuid)).to be_valid
    end

    it 'is not valid without a user' do
      stub_asset_search(123, plate)
      expect(PlateMetadata.new(api: api, barcode: 123)).to_not be_valid
    end

    it 'is not valid without a barcode' do
      expect(PlateMetadata.new(api: api, user: user_uuid)).to_not be_valid
    end

    it 'raises an exception if the barcode is invalid' do
      stub_asset_search(456, nil)
      expect { PlateMetadata.new(api: api, barcode: 456, user: user_uuid) }.to raise_error(Sequencescape::Api::ResourceNotFound)
    end

    it 'can receive plate object as an argument' do
      stub_api_get(plate_uuid, body: json(:plate))
      plate = api.plate.find(plate_uuid)
      expect(PlateMetadata.new(api: api, plate: plate, user: user_uuid)).to be_valid
    end

    it 'creates metadata' do
      stub_asset_search(123, plate)
      plate_metadata = PlateMetadata.new(api: api, barcode: 123, user: user_uuid)
      stub = stub_api_post('custom_metadatum_collections',
                           payload: {
                             custom_metadatum_collection: {
                               user: user_uuid,
                               asset: plate_uuid,
                               metadata: {
                                 created_with_robot: 'robot_barcode'
                               }
                             }
                           },
                           body: json(:v1_custom_metadatum_collection))
      plate_metadata.update!(created_with_robot: 'robot_barcode')
      expect(stub).to have_been_requested
    end

    it 'updates metadata' do
      stub_asset_search(123, plate_with_metadata)

      metadata = attributes_for(:v1_custom_metadatum_collection)
        .fetch(:metadata, {}).merge(created_with_robot: 'robot_barcode')

      plate_metadata = PlateMetadata.new(api: api, barcode: 123, user: user_uuid)
      stub_api_get('custom_metadatum_collection-uuid',
                   body: json(:v1_custom_metadatum_collection,
                              uuid: 'custom_metadatum_collection-uuid'))
      stub_api_get('user-uuid', body: user)
      stub_api_get('asset-uuid', body: plate_with_metadata)
      stub = stub_api_put('custom_metadatum_collection-uuid',
                          payload: {
                            custom_metadatum_collection: { metadata: metadata }
                          },
                          body: json(:v1_custom_metadatum_collection))
      plate_metadata.update!(created_with_robot: 'robot_barcode')
      expect(stub).to have_been_requested
    end
  end
end
