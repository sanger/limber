# frozen_string_literal: true

require 'rails_helper'

describe PlateMetadata do
  include FeatureHelpers

  describe 'without api' do
    it 'is not valid without api' do
      expect(PlateMetadata.new).to_not be_valid
    end
  end

  describe 'with api' do
    let(:user_uuid)                 { SecureRandom.uuid }
    let(:user)                      { json :user, uuid: user_uuid }
    let(:plate_uuid)                { SecureRandom.uuid }
    let(:plate)                     { json :stock_plate, uuid: plate_uuid }
    let(:plate_with_metadata)       { json :stock_plate_with_metadata, uuid: plate_uuid }

    has_a_working_api(times: 1)

    let(:api) { Sequencescape::Api.new(Limber::Application.config.api_connection_options) }

    it 'is not valid without a user' do
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 123 } }, plate)
      expect(PlateMetadata.new(api: api, plate: 123, user: user_uuid)).to be_valid
      expect(PlateMetadata.new(api: api, plate: 123)).to_not be_valid
    end

    it 'is not valid without plate' do
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 123 } }, plate)
      expect(PlateMetadata.new(api: api, plate: 123, user: user_uuid)).to be_valid
      expect(PlateMetadata.new(api: api, user: user_uuid)).to_not be_valid
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 456 } }, nil)
      expect(PlateMetadata.new(api: api, plate: 456, user: user_uuid)).to_not be_valid
    end

    it 'can receive plate object as an argument' do
      stub_api_get(plate_uuid, body: json(:plate))
      plate = api.plate.find(plate_uuid)
      expect(PlateMetadata.new(api: api, plate: plate, user: user_uuid)).to be_valid
    end

    it 'creates metadata' do
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 123 } }, plate)
      plate_metadata = PlateMetadata.new(api: api, plate: 123, user: user_uuid, created_with_robot: 'robot_barcode')
      stub = stub_api_post('custom_metadatum_collections',
                           payload: { custom_metadatum_collection: { user: user_uuid, asset: plate_uuid, metadata: { created_with_robot: 'robot_barcode' } } },
                           body: json(:custom_metadatum_collection))
      plate_metadata.update
      expect(stub).to have_been_requested
    end

    it 'updates metadata' do
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 123 } }, plate_with_metadata)

      metadata = ActiveSupport::JSON.decode(json(:custom_metadatum_collection))['custom_metadatum_collection']['metadata'].merge(created_with_robot: 'robot_barcode')

      plate_metadata = PlateMetadata.new(api: api, plate: 123, user: user_uuid, created_with_robot: 'robot_barcode')
      stub_api_get('custom_metadatum_collection-uuid', body: json(:custom_metadatum_collection, uuid: 'custom_metadatum_collection-uuid'))
      stub_api_get('user-uuid', body: user)
      stub_api_get('asset-uuid', body: plate_with_metadata)
      stub = stub_api_put('custom_metadatum_collection-uuid',
                          payload: { custom_metadatum_collection: { metadata: metadata } },
                          body: json(:custom_metadatum_collection))
      plate_metadata.update
      expect(stub).to have_been_requested
    end
  end
end
