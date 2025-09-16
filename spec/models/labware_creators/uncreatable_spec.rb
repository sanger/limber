# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'
RSpec.describe LabwareCreators::Uncreatable do
  before do
    stub_v2_plate(parent_labware)
    create(:purpose_config, uuid: purpose_uuid, creator_class: 'LabwareCreators::Uncreatable')

    Settings.purposes = {
      parent_purpose.uuid => {
        name: parent_purpose.name,
        asset_type: parent_asset_type
      }
    }
  end

  it_behaves_like 'it does not allow creation'

  let(:parent_uuid) { 'parent-uuid' }
  let(:parent_asset_type) { 'plate' }

  let(:parent_purpose) { create(:v2_purpose) }
  let(:parent_labware) { create(:v2_plate, uuid: parent_uuid, purpose: parent_purpose) }

  let(:asset_type) { 'tube' }
  let(:purpose_name) { 'Uncreatable Purpose' }
  let(:purpose_uuid) { 'uncreatable-purpose' }

  let(:labware_creator) { described_class.new(nil, purpose_uuid:, parent_uuid:) }

  let(:purpose_settings) do
    {
      name: purpose_name,
      asset_type: asset_type,
      creator_class: 'LabwareCreators::Uncreatable'
    }
  end

  describe '.creatable_from?' do
    it 'returns false' do
      expect(described_class.creatable_from?(parent_labware)).to be false
    end
  end

  describe '#parent_labware_type' do
    it 'returns the asset type from settings' do
      expect(labware_creator.parent_labware_type).to eq(parent_asset_type)
    end
  end

  describe '#parent_purpose_name' do
    it 'returns the parent purpose name' do
      expect(labware_creator.parent_purpose_name).to eq(parent_purpose.name)
    end
  end

  describe '#child_purpose_name' do
    context 'when child purpose is not defined' do
      it 'returns unknown' do
        expect(labware_creator.child_purpose_name).to eq('unknown')
      end
    end

    context 'when child purpose is defined' do
      before do
        Settings.purposes[purpose_uuid] = purpose_settings
      end

      it 'returns the child purpose name' do
        expect(labware_creator.child_purpose_name).to eq(purpose_name)
      end
    end
  end

  describe '#child_labware_type' do
    context 'when child purpose is not defined' do
      it 'returns unknown labware type' do
        expect(labware_creator.child_labware_type).to eq('labware')
      end
    end

    context 'when child purpose is defined' do
      before do
        Settings.purposes[purpose_uuid] = purpose_settings
      end

      it 'returns the child labware type' do
        expect(labware_creator.child_labware_type).to eq(asset_type)
      end
    end
  end
end
