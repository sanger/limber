# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabwareMetadata do
  include FeatureHelpers

  let(:user) { create :user }
  let(:updated_metadata) { { created_with_robot: 'robot_barcode' } }

  before { stub_v2_user(user) }

  it 'raises an exception if the barcode is invalid' do
    error = Sequencescape::Api::ResourceNotFound.new('Not found')
    invalid_barcode = 'not_a_barcode'
    allow(Sequencescape::Api::V2::Labware).to receive(:find).with(barcode: invalid_barcode).and_raise(error)

    expect { LabwareMetadata.new(barcode: invalid_barcode, user_uuid: user.uuid) }.to raise_error(error)
  end

  it 'raises an exception if both labware and barcode are nil' do
    expect { LabwareMetadata.new }.to raise_error(ArgumentError)
  end

  context 'plates' do
    let(:plate) { create :v2_stock_plate }
    let(:plate_with_metadata) { create :v2_stock_plate_with_metadata }

    before do
      stub_v2_plate(plate)
      stub_v2_plate(plate_with_metadata)
    end

    context 'by labware' do
      it 'creates metadata' do
        expect_api_v2_posts(
          'CustomMetadatumCollection',
          [user_id: user.id, asset_id: plate.id, metadata: updated_metadata]
        )

        LabwareMetadata.new(labware: plate, user_uuid: user.uuid).update!(updated_metadata)
      end

      it 'updates metadata' do
        metadata = attributes_for(:custom_metadatum_collection).fetch(:metadata, {}).merge(updated_metadata)
        expect(plate_with_metadata.custom_metadatum_collection).to receive(:update!).with(metadata:).and_return(true)

        LabwareMetadata.new(labware: plate_with_metadata, user_uuid: user.uuid).update!(updated_metadata)
      end
    end

    context 'by barcode' do
      it 'creates metadata' do
        expect_api_v2_posts(
          'CustomMetadatumCollection',
          [user_id: user.id, asset_id: plate.id, metadata: updated_metadata]
        )

        LabwareMetadata.new(barcode: plate.barcode.machine, user_uuid: user.uuid).update!(updated_metadata)
      end

      it 'updates metadata' do
        metadata = attributes_for(:custom_metadatum_collection).fetch(:metadata, {}).merge(updated_metadata)
        expect(plate_with_metadata.custom_metadatum_collection).to receive(:update!).with(metadata:).and_return(true)

        LabwareMetadata.new(barcode: plate_with_metadata.barcode.machine, user_uuid: user.uuid).update!(
          updated_metadata
        )
      end
    end
  end

  context 'tubes' do
    let(:tube) { create :v2_stock_tube }
    let(:tube_with_metadata) { create :v2_stock_tube_with_metadata }

    before do
      stub_v2_tube(tube)
      stub_v2_tube(tube_with_metadata)
    end

    context 'by labware' do
      it 'creates metadata' do
        expect_api_v2_posts(
          'CustomMetadatumCollection',
          [user_id: user.id, asset_id: tube.id, metadata: updated_metadata]
        )

        LabwareMetadata.new(labware: tube, user_uuid: user.uuid).update!(updated_metadata)
      end

      it 'updates metadata' do
        metadata = attributes_for(:custom_metadatum_collection).fetch(:metadata, {}).merge(updated_metadata)
        expect(tube_with_metadata.custom_metadatum_collection).to receive(:update!).with(metadata:).and_return(true)

        LabwareMetadata.new(labware: tube_with_metadata, user_uuid: user.uuid).update!(updated_metadata)
      end
    end

    context 'by barcode' do
      it 'creates metadata' do
        expect_api_v2_posts(
          'CustomMetadatumCollection',
          [user_id: user.id, asset_id: tube.id, metadata: updated_metadata]
        )

        LabwareMetadata.new(barcode: tube.barcode.machine, user_uuid: user.uuid).update!(updated_metadata)
      end

      it 'updates metadata' do
        metadata = attributes_for(:custom_metadatum_collection).fetch(:metadata, {}).merge(updated_metadata)
        expect(tube_with_metadata.custom_metadatum_collection).to receive(:update!).with(metadata:).and_return(true)

        LabwareMetadata.new(barcode: tube_with_metadata.barcode.machine, user_uuid: user.uuid).update!(updated_metadata)
      end
    end
  end
end
