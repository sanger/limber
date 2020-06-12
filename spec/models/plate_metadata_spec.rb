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

    it 'raises an exception if the barcode is invalid' do
      stub_asset_search(456, nil)
      expect do
        PlateMetadata.new(api: api, barcode: 456, user: user_uuid)
      end.to raise_error(Sequencescape::Api::ResourceNotFound)
    end

    it 'raises an exception if both plate and barcode are nil' do
      expect { PlateMetadata.new(api: api) }.to raise_error(ArgumentError)
    end

    it 'raises an exception if api is nil' do
      expect { PlateMetadata.new(plate: plate) }.to raise_error(ArgumentError)
    end

    it 'creates metadata' do
      metadata = { created_with_robot: 'robot_barcode' }
      stub = stub_create_plate_metadata(123, plate, plate_uuid, user_uuid, metadata)

      PlateMetadata.new(api: api, barcode: 123, user: user_uuid)
                   .update!(created_with_robot: 'robot_barcode')
      expect(stub).to have_been_requested
    end

    it 'updates metadata' do
      metadata = attributes_for(:v1_custom_metadatum_collection)
                 .fetch(:metadata, {}).merge(created_with_robot: 'robot_barcode')
      stub = stub_update_plate_metadata(123, plate_with_metadata, user, metadata)

      PlateMetadata.new(api: api, barcode: 123, user: user_uuid)
                   .update!(created_with_robot: 'robot_barcode')
      expect(stub).to have_been_requested
    end
  end
end
