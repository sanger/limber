# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/baited_plate'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::BaitedPlate do
  it_behaves_like 'it only allows creation from plates'

  subject { LabwareCreators::BaitedPlate.new(api, form_attributes) }

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose) { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid) { 'parent-uuid' }
  let(:requests) do
    Array.new(6) { |i| create :library_request, :state => 'started', :uuid => "request-#{i}", 'submission_id' => '2' }
  end
  let(:parent) { create :v2_plate, uuid: parent_uuid, outer_requests: requests, barcode_number: 2 }
  let(:child) { create :v2_plate, uuid: 'child-uuid', outer_requests: requests, barcode_number: 3 }
  let(:transfer_template_uuid) { 'custom-pooling' }
  let(:transfer_template) { json :transfer_template, uuid: transfer_template_uuid }

  let(:form_attributes) { { user_uuid: user_uuid, purpose_uuid: purpose_uuid, parent_uuid: parent_uuid } }

  let(:transfer_requests) do
    WellHelpers.column_order(96)[0, 6].map do |well_name|
      { 'source_asset' => "2-well-#{well_name}", 'target_asset' => "3-well-#{well_name}", 'submission_id' => '2' }
    end
  end

  it 'should have page' do
    expect(LabwareCreators::BaitedPlate.page).to eq 'baited_plate'
  end

  context 'create plate' do
    has_a_working_api

    let!(:bait_library_layout_preview_request) do
      stub_api_post(
        'bait_library_layouts/preview',
        payload: {
          bait_library_layout: {
            plate: parent_uuid,
            user: user_uuid
          }
        },
        body: json(:bait_library_layout)
      )
    end

    let!(:bait_library_layout_request) do
      stub_api_post(
        'bait_library_layouts',
        payload: {
          bait_library_layout: {
            plate: 'child-uuid',
            user: user_uuid
          }
        },
        body: json(:bait_library_layout)
      )
    end

    let!(:plate_creation_request) do
      stub_api_post(
        'plate_creations',
        payload: {
          plate_creation: {
            parent: parent_uuid,
            child_purpose: purpose_uuid,
            user: user_uuid
          }
        },
        body: json(:plate_creation)
      )
    end

    before do
      stub_v2_plate(parent, stub_search: false)
      stub_v2_plate(child, stub_search: false)
    end

    let!(:transfer_creation_request) do
      stub_api_post(
        'transfer_request_collections',
        payload: {
          transfer_request_collection: {
            user: user_uuid,
            transfer_requests: transfer_requests
          }
        },
        body: '{}'
      )
    end

    it 'should make an api call for bait library layout preview' do
      bait_library_layout_preview = {
        'A1' => 'Human all exon 50MB',
        'B1' => 'Human all exon 50MB',
        'C1' => 'Mouse all exon',
        'D1' => 'Mouse all exon'
      }
      expect(subject.bait_library_layout_preview).to eq bait_library_layout_preview
    end

    it 'should create objects' do
      expect(subject.create_labware!).to eq true
    end
  end
end
