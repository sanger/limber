# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabwareMetadata do
  include FeatureHelpers

  describe 'with api' do
    let(:user_uuid) { SecureRandom.uuid }
    let(:user) { json :v1_user, uuid: user_uuid }
    let(:plate_uuid) { SecureRandom.uuid }
    let(:plate) { json :stock_plate, uuid: plate_uuid }
    let(:plate_with_metadata) { json :stock_plate_with_metadata, uuid: plate_uuid }

    let(:tube_uuid) { SecureRandom.uuid }
    let(:tube) { json :stock_tube, uuid: tube_uuid }
    let(:tube_with_metadata) { json :stock_tube_with_metadata, uuid: tube_uuid }

    has_a_working_api

    it 'raises an exception if the barcode is invalid' do
      stub_asset_search(456, nil)
      expect { LabwareMetadata.new(api: api, barcode: 456, user: user_uuid) }.to raise_error(
        Sequencescape::Api::ResourceNotFound
      )
    end

    context 'plates' do
      it 'raises an exception if both plate and barcode are nil' do
        expect { LabwareMetadata.new(api: api) }.to raise_error(ArgumentError)
      end

      it 'raises an exception if api is nil' do
        expect { LabwareMetadata.new(labware: plate) }.to raise_error(ArgumentError)
      end

      it 'creates metadata' do
        metadata = { created_with_robot: 'robot_barcode' }
        stub = stub_create_labware_metadata(123, plate, plate_uuid, user_uuid, metadata)

        LabwareMetadata.new(api: api, barcode: 123, user: user_uuid).update!(created_with_robot: 'robot_barcode')
        expect(stub).to have_been_requested
      end

      it 'updates metadata' do
        metadata =
          attributes_for(:v1_custom_metadatum_collection)
            .fetch(:metadata, {})
            .merge(created_with_robot: 'robot_barcode')
        stub = stub_update_labware_metadata(123, plate_with_metadata, user, metadata)

        LabwareMetadata.new(api: api, barcode: 123, user: user_uuid).update!(created_with_robot: 'robot_barcode')
        expect(stub).to have_been_requested
      end
    end

    context 'tubes' do
      it 'raises an exception if both tube and barcode are nil' do
        expect { LabwareMetadata.new(api: api) }.to raise_error(ArgumentError)
      end

      it 'raises an exception if api is nil' do
        expect { LabwareMetadata.new(labware: tube) }.to raise_error(ArgumentError)
      end

      it 'creates metadata' do
        metadata = { created_with_robot: 'robot_barcode' }
        stub = stub_create_labware_metadata(123, tube, tube_uuid, user_uuid, metadata)

        LabwareMetadata.new(api: api, barcode: 123, user: user_uuid).update!(created_with_robot: 'robot_barcode')
        expect(stub).to have_been_requested
      end

      it 'updates metadata' do
        metadata =
          attributes_for(:v1_custom_metadatum_collection)
            .fetch(:metadata, {})
            .merge(created_with_robot: 'robot_barcode')
        stub = stub_update_labware_metadata(123, plate_with_metadata, user, metadata)

        LabwareMetadata.new(api: api, barcode: 123, user: user_uuid).update!(created_with_robot: 'robot_barcode')
        expect(stub).to have_been_requested
      end
    end
  end
end
