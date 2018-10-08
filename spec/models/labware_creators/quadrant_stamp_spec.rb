# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative '../../support/shared_tagging_examples'
require_relative 'shared_examples'

# Up to four 96 well plates are transferred onto a single 384 well plate.
# Filtering can be done via primer panel.
RSpec.describe LabwareCreators::QuadrantStamp do
  it_behaves_like 'it only allows creation from plates'

  has_a_working_api

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:parent2_uuid) { 'example-plate2-uuid' }
  let(:child_uuid) { 'child-uuid' }
  let(:requests) { Array.new(96) { |i| create :gbs_library_request, state: 'started', uuid: "request-#{i}" } }
  let(:requests2) { Array.new(96) { |i| create :gbs_library_request, state: 'started', uuid: "request-#{i}" } }
  let(:parent) { create :v2_plate_with_primer_panels, barcode_number: '2', uuid: parent_uuid, size: 96, outer_requests: requests, well_count: 10 }
  let(:parent2) { create :v2_plate_with_primer_panels, barcode_number: '3', uuid: parent2_uuid, size: 96, outer_requests: requests2, well_count: 10 }
  let(:child_plate) { create :v2_plate, uuid: child_uuid, barcode_number: '4', size: 384 }
  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  before do
    create :purpose_config, name: child_purpose_name
    stub_v2_plate(parent, stub_search: false)
    stub_v2_plate(parent2, stub_search: false)
    stub_v2_plate(child_plate, stub_search: false)
  end

  context 'on new' do
    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid:  parent_uuid
      }
    end

    subject do
      LabwareCreators::QuadrantStamp.new(api, form_attributes)
    end

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::QuadrantStamp
    end

    it 'renders the "quadrant_stamp" page' do
      expect(subject.page).to eq('quadrant_stamp')
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_purpose_uuid)
    end
  end

  context 'on create' do
    subject do
      LabwareCreators::QuadrantStamp.new(api, form_attributes.merge(user_uuid: user_uuid))
    end

    let(:form_attributes) do
      {
        parent_uuid: parent_uuid,
        purpose_uuid: child_purpose_uuid,
        transfers: [
          { source_plate: parent_uuid, source_asset: '2-well-A1', outer_request: 'request-0', new_target: { location: 'A1' } },
          { source_plate: parent_uuid, source_asset: '2-well-B1', outer_request: 'request-1', new_target: { location: 'C1' } },
          { source_plate: parent_uuid, source_asset: '2-well-C1', outer_request: 'request-2', new_target: { location: 'E1' } },
          { source_plate: parent_uuid, source_asset: '2-well-D1', outer_request: 'request-3', new_target: { location: 'G1' } },
          { source_plate: parent_uuid, source_asset: '2-well-E1', outer_request: 'request-4', new_target: { location: 'I1' } },
          { source_plate: parent_uuid, source_asset: '2-well-F1', outer_request: 'request-5', new_target: { location: 'K1' } },
          { source_plate: parent_uuid, source_asset: '2-well-G1', outer_request: 'request-6', new_target: { location: 'M1' } },
          { source_plate: parent_uuid, source_asset: '2-well-H1', outer_request: 'request-7', new_target: { location: 'O1' } },
          { source_plate: parent_uuid, source_asset: '2-well-A2', outer_request: 'request-8', new_target: { location: 'A3' } },
          { source_plate: parent_uuid, source_asset: '2-well-B2', outer_request: 'request-9', new_target: { location: 'C3' } },
          { source_plate: parent2_uuid, source_asset: '3-well-A1', outer_request: 'request-0', new_target: { location: 'B1' } },
          { source_plate: parent2_uuid, source_asset: '3-well-B1', outer_request: 'request-1', new_target: { location: 'D1' } },
          { source_plate: parent2_uuid, source_asset: '3-well-C1', outer_request: 'request-2', new_target: { location: 'F1' } },
          { source_plate: parent2_uuid, source_asset: '3-well-D1', outer_request: 'request-3', new_target: { location: 'H1' } },
          { source_plate: parent2_uuid, source_asset: '3-well-E1', outer_request: 'request-4', new_target: { location: 'J1' } },
          { source_plate: parent2_uuid, source_asset: '3-well-F1', outer_request: 'request-5', new_target: { location: 'L1' } },
          { source_plate: parent2_uuid, source_asset: '3-well-G1', outer_request: 'request-6', new_target: { location: 'N1' } },
          { source_plate: parent2_uuid, source_asset: '3-well-H1', outer_request: 'request-7', new_target: { location: 'P1' } },
          { source_plate: parent2_uuid, source_asset: '3-well-A2', outer_request: 'request-8', new_target: { location: 'B3' } },
          { source_plate: parent2_uuid, source_asset: '3-well-B2', outer_request: 'request-9', new_target: { location: 'D3' } }
        ]
      }
    end

    let!(:pooled_plate_creation_request) do
      stub_api_post(
        'pooled_plate_creations',
        payload: {
          pooled_plate_creation: {
            user: user_uuid,
            child_purpose: child_purpose_uuid,
            parents: [parent_uuid, parent2_uuid]
          }
        },
        body: json(:plate_creation, child_uuid: child_uuid)
      )
    end

    let(:transfer_requests) do
      [
        { source_asset: '2-well-A1', outer_request: 'request-0', target_asset: '4-well-A1' },
        { source_asset: '2-well-B1', outer_request: 'request-1', target_asset: '4-well-C1' },
        { source_asset: '2-well-C1', outer_request: 'request-2', target_asset: '4-well-E1' },
        { source_asset: '2-well-D1', outer_request: 'request-3', target_asset: '4-well-G1' },
        { source_asset: '2-well-E1', outer_request: 'request-4', target_asset: '4-well-I1' },
        { source_asset: '2-well-F1', outer_request: 'request-5', target_asset: '4-well-K1' },
        { source_asset: '2-well-G1', outer_request: 'request-6', target_asset: '4-well-M1' },
        { source_asset: '2-well-H1', outer_request: 'request-7', target_asset: '4-well-O1' },
        { source_asset: '2-well-A2', outer_request: 'request-8', target_asset: '4-well-A3' },
        { source_asset: '2-well-B2', outer_request: 'request-9', target_asset: '4-well-C3' },
        { source_asset: '3-well-A1', outer_request: 'request-0', target_asset: '4-well-B1' },
        { source_asset: '3-well-B1', outer_request: 'request-1', target_asset: '4-well-D1' },
        { source_asset: '3-well-C1', outer_request: 'request-2', target_asset: '4-well-F1' },
        { source_asset: '3-well-D1', outer_request: 'request-3', target_asset: '4-well-H1' },
        { source_asset: '3-well-E1', outer_request: 'request-4', target_asset: '4-well-J1' },
        { source_asset: '3-well-F1', outer_request: 'request-5', target_asset: '4-well-L1' },
        { source_asset: '3-well-G1', outer_request: 'request-6', target_asset: '4-well-N1' },
        { source_asset: '3-well-H1', outer_request: 'request-7', target_asset: '4-well-P1' },
        { source_asset: '3-well-A2', outer_request: 'request-8', target_asset: '4-well-B3' },
        { source_asset: '3-well-B2', outer_request: 'request-9', target_asset: '4-well-D3' }
      ]
    end

    let!(:transfer_creation_request) do
      stub_api_post('transfer_request_collections',
                    payload: { transfer_request_collection: {
                      user: user_uuid,
                      transfer_requests: transfer_requests
                    } },
                    body: '{}')
    end

    context '#save!' do
      it 'creates a plate!' do
        subject.save!
        expect(pooled_plate_creation_request).to have_been_made.once
        expect(transfer_creation_request).to have_been_made.once
      end
    end
  end
end
