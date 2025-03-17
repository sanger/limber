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

  let(:parent1) do
    create :v2_stock_tube,
           uuid: parent1_tube_uuid,
           purpose_uuid: 'example-parent-tube-purpose1-uuid',
           receptacle: parent1_receptacle
  end
  let(:parent2) do
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

  before do
    stub_v2_tube(parent1, stub_search: false)
    stub_v2_tube(parent2, stub_search: false)
  end

  context 'on new' do
    let(:form_attributes) do
      {
        purpose_uuid: child_tube_purpose_uuid,
        parent_uuid: parent1_tube_uuid,
        transfers: [{ source_tube_uuid: parent1_tube_uuid }, { source_tube_uuid: parent2_tube_uuid }]
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
        transfers: [{ source_tube_uuid: parent1_tube_uuid }, { source_tube_uuid: parent2_tube_uuid }]
      }
    end

    let(:transfer_requests_attributes) do
      [
        { source_asset: parent1_tube_uuid, target_asset: child_tube_uuid },
        { source_asset: parent2_tube_uuid, target_asset: child_tube_uuid }
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
          tube_attributes: [{ name: [parent1.human_barcode, parent2.human_barcode].join(':') }]
        }
      ]
    end

    context '#save!' do
      setup { allow(subject).to receive(:parents).and_return([parent1, parent2]) }

      it 'creates a tube' do
        expect_specific_tube_creation
        expect_transfer_request_collection_creation

        subject.save!
      end
    end
  end
end
