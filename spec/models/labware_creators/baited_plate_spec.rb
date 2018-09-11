# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/baited_plate'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::BaitedPlate do
  it_behaves_like 'it only allows creation from plates'

  subject do
    LabwareCreators::BaitedPlate.new(form_attributes)
  end

  let(:user_uuid)    { SecureRandom.uuid }
  let(:user)         { json :user, uuid: user_uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose)      { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid)  { SecureRandom.uuid }
  let(:parent)       { create :v2_plate, uuid: parent_uuid, pool_sizes: [3, 3] }
  let(:transfer_template_uuid) { 'custom-pooling' }
  let(:transfer_template) { json :transfer_template, uuid: transfer_template_uuid }

  let(:form_attributes) do
    {
      user_uuid: user_uuid,
      purpose_uuid: purpose_uuid,
      parent_uuid: parent_uuid,
      api: api
    }
  end

  it 'should have page' do
    expect(LabwareCreators::BaitedPlate.page).to eq 'baited_plate'
  end

  context 'create plate' do
    has_a_working_api

    let!(:bait_library_layout_preview_request) do
      stub_api_post('bait_library_layouts/preview',
                    payload: { bait_library_layout: {
                      plate: parent_uuid,
                      user: user_uuid
                    } },
                    body: json(:bait_library_layout))
    end

    let!(:bait_library_layout_request) do
      stub_api_post('bait_library_layouts',
                    payload: { bait_library_layout: {
                      plate: 'child-uuid',
                      user: user_uuid
                    } },
                    body: json(:bait_library_layout))
    end

    let!(:plate_creation_request) do
      stub_api_post('plate_creations',
                    payload: { plate_creation: {
                      parent: parent_uuid,
                      child_purpose: purpose_uuid,
                      user: user_uuid
                    } },
                    body: json(:plate_creation))
    end

    let!(:plate_request) do
      stub_v2_plate(parent, stub_search: false)
    end

    let(:expected_transfers) { WellHelpers.stamp_hash(96) }

    let!(:transfer_template_request) do
      stub_api_get(transfer_template_uuid, body: transfer_template)
    end

    let!(:transfer_creation_request) do
      stub_api_post(transfer_template_uuid,
                    payload: { transfer: {
                      destination: 'child-uuid',
                      source: parent_uuid,
                      user: user_uuid,
                      transfers: expected_transfers
                    } },
                    body: '{}')
    end

    it 'should make an api call for bait library layout preview' do
      bait_library_layout_preview = { 'A1' => 'Human all exon 50MB', 'B1' => 'Human all exon 50MB', 'C1' => 'Mouse all exon', 'D1' => 'Mouse all exon' }
      expect(subject.bait_library_layout_preview).to eq bait_library_layout_preview
    end

    it 'should create objects' do
      expect(subject.create_labware!).to eq true
    end
  end
end
