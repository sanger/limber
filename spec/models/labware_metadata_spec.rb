# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabwareMetadata do
  include FeatureHelpers

  let(:user) { create :user }
  let(:updated_metadata) { { created_with_robot: 'robot_barcode' } }

  before { stub_v2_user(user) }

  it 'raises an exception if both labware and barcode are nil' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it 'uses the labware if both labware and barcode are given' do
    plate = create :v2_stock_plate
    stub_v2_plate(plate)

    expect(Sequencescape::Api::V2::Labware).not_to receive(:find)
    described_class.new(labware: plate, barcode: 'not_a_barcode', user_uuid: user.uuid)
  end

  it 'raises an exception if the barcode is invalid' do
    barcode = 'not_a_barcode'
    error = JsonApiClient::Errors::NotFound

    allow(Sequencescape::Api::V2::Labware).to receive(:find).with(hash_including(barcode:)).and_return([])

    expect { described_class.new(barcode: barcode, user_uuid: user.uuid) }.to raise_error(error)
  end

  context 'plates' do
    let(:plate) { create :v2_stock_plate }
    let(:plate_with_metadata) { create :v2_stock_plate_with_metadata }

    let(:custom_metadatum_collections_attributes) { [user_id: user.id, asset_id: plate.id, metadata: updated_metadata] }

    before do
      stub_v2_plate(plate)
      stub_v2_plate(plate_with_metadata)
    end

    context 'by labware' do
      it 'creates metadata' do
        expect_custom_metadatum_collection_creation

        described_class.new(labware: plate, user_uuid: user.uuid).update!(updated_metadata)
      end

      it 'updates metadata' do
        metadata = attributes_for(:custom_metadatum_collection).fetch(:metadata, {}).merge(updated_metadata)
        expect(plate_with_metadata.custom_metadatum_collection).to receive(:update!).with(metadata:).and_return(true)

        described_class.new(labware: plate_with_metadata, user_uuid: user.uuid).update!(updated_metadata)
      end
    end

    context 'by barcode' do
      it 'creates metadata' do
        expect_custom_metadatum_collection_creation

        described_class.new(barcode: plate.barcode.machine, user_uuid: user.uuid).update!(updated_metadata)
      end

      it 'updates metadata' do
        metadata = attributes_for(:custom_metadatum_collection).fetch(:metadata, {}).merge(updated_metadata)
        expect(plate_with_metadata.custom_metadatum_collection).to receive(:update!).with(metadata:).and_return(true)

        described_class.new(barcode: plate_with_metadata.barcode.machine, user_uuid: user.uuid).update!(
          updated_metadata
        )
      end
    end
  end

  context 'tubes' do
    let(:tube) { create :v2_stock_tube }
    let(:tube_with_metadata) { create :v2_stock_tube_with_metadata }

    let(:custom_metadatum_collections_attributes) { [user_id: user.id, asset_id: tube.id, metadata: updated_metadata] }

    before do
      stub_v2_tube(tube)
      stub_v2_tube(tube_with_metadata)
    end

    context 'by labware' do
      it 'creates metadata' do
        expect_custom_metadatum_collection_creation

        described_class.new(labware: tube, user_uuid: user.uuid).update!(updated_metadata)
      end

      it 'updates metadata' do
        metadata = attributes_for(:custom_metadatum_collection).fetch(:metadata, {}).merge(updated_metadata)
        expect(tube_with_metadata.custom_metadatum_collection).to receive(:update!).with(metadata:).and_return(true)

        described_class.new(labware: tube_with_metadata, user_uuid: user.uuid).update!(updated_metadata)
      end
    end

    context 'by barcode' do
      it 'creates metadata' do
        expect_custom_metadatum_collection_creation

        described_class.new(barcode: tube.barcode.machine, user_uuid: user.uuid).update!(updated_metadata)
      end

      it 'updates metadata' do
        metadata = attributes_for(:custom_metadatum_collection).fetch(:metadata, {}).merge(updated_metadata)
        expect(tube_with_metadata.custom_metadatum_collection).to receive(:update!).with(metadata:).and_return(true)

        described_class.new(barcode: tube_with_metadata.barcode.machine, user_uuid: user.uuid).update!(updated_metadata)
      end
    end
  end
end
