# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# 2 parent tubes are blended into a single child tube
RSpec.describe LabwareCreators::BlendedTube do
  it_behaves_like 'it only allows creation from tubes'

  has_a_working_api

  let(:parent1_tube_uuid) { 'parent-tube1-uuid' }
  let(:parent2_tube_uuid) { 'parent-tube2-uuid' }

  let(:parent1_receptacle_uuid) { 'parent-receptacle1-uuid' }
  let(:parent2_receptacle_uuid) { 'parent-receptacle2-uuid' }
  let(:parent_receptacle_uuids) { [parent1_receptacle_uuid, parent2_receptacle_uuid] }

  let(:parent1_receptacle) { create(:v2_receptacle, uuid: parent1_receptacle_uuid, qc_results: []) }
  let(:parent2_receptacle) { create(:v2_receptacle, uuid: parent2_receptacle_uuid, qc_results: []) }

  let(:parent1_tube) do
    create :v2_stock_tube,
           uuid: parent1_tube_uuid,
           purpose_uuid: 'example-parent-tube-purpose1-uuid',
           receptacle: parent1_receptacle
  end
  let(:parent2_tube) do
    create :v2_stock_tube,
           uuid: parent2_tube_uuid,
           purpose_uuid: 'example-parent-tube-purpose2-uuid',
           receptacle: parent2_receptacle
  end

  let(:child_tube_purpose_uuid) { 'child-purpose' }
  let(:child_tube_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }
  let(:user) { json :user, uuid: user_uuid }

  let!(:child_tube_purpose_config) do
    create :blended_tube_purpose_config, name: child_tube_purpose_name, uuid: child_tube_purpose_uuid
  end

  let(:child_tube_uuid) { 'child-tube-uuid' }

  let(:child_tube) do
    create :v2_tube,
           uuid: child_tube_uuid,
           purpose_name: child_tube_purpose_name,
           barcode_number: '5',
           name: 'blended-tube'
  end

  before do
    stub_v2_tube(parent1_tube, stub_search: false)
    stub_v2_tube(parent2_tube, stub_search: false)
  end

  context 'validations' do
    it 'validates presence of transfers' do
      blended_tube = LabwareCreators::BlendedTube.new(api, purpose_uuid: child_tube_purpose_uuid)
      expect(blended_tube).not_to be_valid
      expect(blended_tube.errors[:transfers]).to include("can't be blank")
    end
  end

  context '#create_labware!' do
    subject { LabwareCreators::BlendedTube.new(api, form_attributes.merge(user_uuid:)) }

    let(:form_attributes) do
      {
        parent_uuid: parent1_tube_uuid,
        purpose_uuid: child_tube_purpose_uuid,
        transfers: [{ source_tube: parent1_tube_uuid }, { source_tube: parent2_tube_uuid }]
      }
    end

    let(:transfer_requests_attributes) do
      [
        { source_asset: parent1_tube_uuid, target_asset: child_tube_uuid, aliquot_attributes: { tag_depth: '0' } },
        { source_asset: parent2_tube_uuid, target_asset: child_tube_uuid, aliquot_attributes: { tag_depth: '1' } }
      ]
    end

    before do
      allow(subject).to receive(:create_child_tube).and_return(child_tube)
      allow(subject).to receive(:transfer_request_attributes).and_return(transfer_requests_attributes)
    end

    it 'creates a child tube and performs transfers' do
      expect(Sequencescape::Api::V2::TransferRequestCollection).to receive(:create!).with(
        transfer_requests_attributes:,
        user_uuid:
      )

      # Call the private method using `send`
      subject.send(:create_labware!)
    end
  end

  context '#request_hash' do
    subject { LabwareCreators::BlendedTube.new(api, form_attributes.merge(user_uuid:)) }

    let(:form_attributes) do
      {
        parent_uuid: parent1_tube_uuid,
        purpose_uuid: child_tube_purpose_uuid,
        transfers: [{ source_tube: parent1_tube_uuid }, { source_tube: parent2_tube_uuid }]
      }
    end

    before do
      # Stub the @child_tube instance variable
      allow(subject).to receive(:create_child_tube).and_return(child_tube)
      subject.instance_variable_set(:@child_tube, child_tube)
    end

    it 'returns the correct request hash' do
      parent_tube = parent1_tube
      index = 0

      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(uuid: parent_tube.uuid).and_return(parent_tube)

      result = subject.send(:request_hash, { source_tube: parent_tube.uuid }, index)

      expect(result).to eq(
        source_asset: parent_tube.uuid,
        target_asset: child_tube_uuid,
        aliquot_attributes: {
          tag_depth: index.to_s
        }
      )
    end
  end

  context 'on new' do
    let(:form_attributes) do
      {
        purpose_uuid: child_tube_purpose_uuid,
        parent_uuid: parent1_tube_uuid,
        transfers: [{ source_tube: parent1_tube_uuid }, { source_tube: parent2_tube_uuid }]
      }
    end

    subject { LabwareCreators::BlendedTube.new(api, form_attributes) }

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::BlendedTube
    end

    it 'renders the "blended_tube" page' do
      expect(subject.page).to eq('blended_tube')
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_tube_purpose_uuid)
    end
  end

  context 'on create' do
    subject { LabwareCreators::BlendedTube.new(api, form_attributes.merge(user_uuid:)) }

    let(:form_attributes) do
      {
        parent_uuid: parent1_tube_uuid,
        purpose_uuid: child_tube_purpose_uuid,
        transfers: [{ source_tube: parent1_tube_uuid }, { source_tube: parent2_tube_uuid }]
      }
    end

    let(:transfer_requests_attributes) do
      [
        { source_asset: parent1_tube_uuid, target_asset: child_tube_uuid, aliquot_attributes: { tag_depth: '0' } },
        { source_asset: parent2_tube_uuid, target_asset: child_tube_uuid, aliquot_attributes: { tag_depth: '1' } }
      ]
    end

    let(:child_tube) do
      create :v2_tube,
             uuid: child_tube_uuid,
             purpose_name: child_tube_purpose_name,
             barcode_number: '5',
             name: 'blended-tube'
    end

    let(:specific_tubes_attributes) do
      [
        {
          uuid: child_tube_purpose_uuid,
          parent_uuids: [parent1_tube_uuid, parent2_tube_uuid],
          child_tubes: [child_tube],
          tube_attributes: [{ name: [parent1_tube.human_barcode, parent2_tube.human_barcode].join(':') }]
        }
      ]
    end

    context '#save!' do
      setup { allow(subject).to receive(:parents).and_return([parent1_tube, parent2_tube]) }

      it 'creates a tube' do
        expect_specific_tube_creation
        expect_transfer_request_collection_creation

        subject.save!
      end
    end
  end
end
