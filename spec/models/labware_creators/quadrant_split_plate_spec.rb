# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative '../../support/shared_tagging_examples'
require_relative 'shared_examples'

# Splits one 384 well plate into 4x96 well plates
RSpec.describe LabwareCreators::QuadrantSplitPlate do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  has_a_working_api

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:parent_plate_size) { 384 }
  let(:child_plate_size) { 96 }

  let(:plate) { create :v2_stock_plate, uuid: parent_uuid, barcode_number: '2', size: parent_plate_size, outer_requests: requests }

  let(:child_plate_a) { create :v2_plate, uuid: 'child-a-uuid', barcode_number: '3', size: child_plate_size, outer_requests: quad_a_requests }
  let(:child_plate_b) { create :v2_plate, uuid: 'child-b-uuid', barcode_number: '4', size: child_plate_size, outer_requests: quad_b_requests }
  let(:child_plate_c) { create :v2_plate, uuid: 'child-c-uuid', barcode_number: '5', size: child_plate_size, outer_requests: quad_c_requests }
  let(:child_plate_d) { create :v2_plate, uuid: 'child-d-uuid', barcode_number: '6', size: child_plate_size, outer_requests: quad_d_requests }

  let(:quad_a_requests) { Array.new(child_plate_size) { |i| create :library_request, state: 'started', uuid: "request-a-#{i}" } }
  let(:quad_b_requests) { Array.new(child_plate_size) { |i| create :library_request, state: 'started', uuid: "request-b-#{i}" } }
  let(:quad_c_requests) { Array.new(child_plate_size) { |i| create :library_request, state: 'started', uuid: "request-c-#{i}" } }
  let(:quad_d_requests) { Array.new(child_plate_size) { |i| create :library_request, state: 'started', uuid: "request-d-#{i}" } }
  let(:requests) do
    quads = [
      [quad_a_requests, quad_c_requests],
      [quad_b_requests, quad_d_requests]
    ]
    Array.new(384) do |i|
      row = i % 16
      col = i / 16
      quad = quads[row % 2][col % 2]
      index = (row / 2) + (8 * (col / 2))
      quad[index]
    end
  end

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  before do
    create(:purpose_config, name: child_purpose_name, uuid: child_purpose_uuid)
    allow(Sequencescape::Api::V2::Plate).to receive(:find_all).with(
      {
        uuid: ['child-a-uuid', 'child-b-uuid', 'child-c-uuid', 'child-d-uuid']
      },
      includes: ['wells']
    ).and_return([child_plate_a, child_plate_b, child_plate_c, child_plate_d])
    stub_v2_plate(plate, stub_search: false)
  end

  let(:form_attributes) do
    {
      purpose_uuid: child_purpose_uuid,
      parent_uuid: parent_uuid,
      user_uuid: user_uuid
    }
  end

  subject do
    LabwareCreators::QuadrantSplitPlate.new(api, form_attributes)
  end

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a LabwareCreators::QuadrantSplitPlate
    end
  end

  shared_examples 'a quad-split plate creator' do
    describe '#save!' do
      let!(:plate_creation_request) do
        stub_api_post('plate_creations',
                      payload: { plate_creation: {
                        parent: parent_uuid,
                        child_purpose: child_purpose_uuid,
                        user: user_uuid
                      } },
                      body: [
                        json(:plate_creation, child_uuid: 'child-a-uuid'),
                        json(:plate_creation, child_uuid: 'child-b-uuid'),
                        json(:plate_creation, child_uuid: 'child-c-uuid'),
                        json(:plate_creation, child_uuid: 'child-d-uuid')
                      ])
      end

      let!(:transfer_creation_request) do
        stub_api_post('transfer_request_collections',
                      payload: { transfer_request_collection: {
                        user: user_uuid,
                        transfer_requests: transfer_requests
                      } },
                      body: '{}')
      end

      it 'makes the expected requests' do
        expect(subject.save!).to eq true
        expect(plate_creation_request).to have_been_made.times(4)
        expect(transfer_creation_request).to have_been_made
        expect(subject.redirection_target).to eq(plate)
      end
    end
  end

  context '384 well plate' do
    let(:plate_size) { 384 }

    let(:transfer_requests) do
      # Hardcoding this to be explicit
      [
        { source_asset: '2-well-A1', target_asset: '3-well-A1', outer_request: 'request-a-0' },
        { source_asset: '2-well-B1', target_asset: '4-well-A1', outer_request: 'request-b-0' },
        { source_asset: '2-well-C1', target_asset: '3-well-B1', outer_request: 'request-a-1' },
        { source_asset: '2-well-D1', target_asset: '4-well-B1', outer_request: 'request-b-1' },
        { source_asset: '2-well-E1', target_asset: '3-well-C1', outer_request: 'request-a-2' },
        { source_asset: '2-well-F1', target_asset: '4-well-C1', outer_request: 'request-b-2' },
        { source_asset: '2-well-G1', target_asset: '3-well-D1', outer_request: 'request-a-3' },
        { source_asset: '2-well-H1', target_asset: '4-well-D1', outer_request: 'request-b-3' },
        { source_asset: '2-well-I1', target_asset: '3-well-E1', outer_request: 'request-a-4' },
        { source_asset: '2-well-J1', target_asset: '4-well-E1', outer_request: 'request-b-4' },
        { source_asset: '2-well-K1', target_asset: '3-well-F1', outer_request: 'request-a-5' },
        { source_asset: '2-well-L1', target_asset: '4-well-F1', outer_request: 'request-b-5' },
        { source_asset: '2-well-M1', target_asset: '3-well-G1', outer_request: 'request-a-6' },
        { source_asset: '2-well-N1', target_asset: '4-well-G1', outer_request: 'request-b-6' },
        { source_asset: '2-well-O1', target_asset: '3-well-H1', outer_request: 'request-a-7' },
        { source_asset: '2-well-P1', target_asset: '4-well-H1', outer_request: 'request-b-7' },
        { source_asset: '2-well-A2', target_asset: '5-well-A1', outer_request: 'request-c-0' },
        { source_asset: '2-well-B2', target_asset: '6-well-A1', outer_request: 'request-d-0' },
        { source_asset: '2-well-C2', target_asset: '5-well-B1', outer_request: 'request-c-1' },
        { source_asset: '2-well-D2', target_asset: '6-well-B1', outer_request: 'request-d-1' },
        { source_asset: '2-well-E2', target_asset: '5-well-C1', outer_request: 'request-c-2' },
        { source_asset: '2-well-F2', target_asset: '6-well-C1', outer_request: 'request-d-2' },
        { source_asset: '2-well-G2', target_asset: '5-well-D1', outer_request: 'request-c-3' },
        { source_asset: '2-well-H2', target_asset: '6-well-D1', outer_request: 'request-d-3' },
        { source_asset: '2-well-I2', target_asset: '5-well-E1', outer_request: 'request-c-4' },
        { source_asset: '2-well-J2', target_asset: '6-well-E1', outer_request: 'request-d-4' },
        { source_asset: '2-well-K2', target_asset: '5-well-F1', outer_request: 'request-c-5' },
        { source_asset: '2-well-L2', target_asset: '6-well-F1', outer_request: 'request-d-5' },
        { source_asset: '2-well-M2', target_asset: '5-well-G1', outer_request: 'request-c-6' },
        { source_asset: '2-well-N2', target_asset: '6-well-G1', outer_request: 'request-d-6' },
        { source_asset: '2-well-O2', target_asset: '5-well-H1', outer_request: 'request-c-7' },
        { source_asset: '2-well-P2', target_asset: '6-well-H1', outer_request: 'request-d-7' },
        { source_asset: '2-well-A3', target_asset: '3-well-A2', outer_request: 'request-a-8' },
        { source_asset: '2-well-B3', target_asset: '4-well-A2', outer_request: 'request-b-8' },
        { source_asset: '2-well-C3', target_asset: '3-well-B2', outer_request: 'request-a-9' },
        { source_asset: '2-well-D3', target_asset: '4-well-B2', outer_request: 'request-b-9' },
        { source_asset: '2-well-E3', target_asset: '3-well-C2', outer_request: 'request-a-10' },
        { source_asset: '2-well-F3', target_asset: '4-well-C2', outer_request: 'request-b-10' },
        { source_asset: '2-well-G3', target_asset: '3-well-D2', outer_request: 'request-a-11' },
        { source_asset: '2-well-H3', target_asset: '4-well-D2', outer_request: 'request-b-11' },
        { source_asset: '2-well-I3', target_asset: '3-well-E2', outer_request: 'request-a-12' },
        { source_asset: '2-well-J3', target_asset: '4-well-E2', outer_request: 'request-b-12' },
        { source_asset: '2-well-K3', target_asset: '3-well-F2', outer_request: 'request-a-13' },
        { source_asset: '2-well-L3', target_asset: '4-well-F2', outer_request: 'request-b-13' },
        { source_asset: '2-well-M3', target_asset: '3-well-G2', outer_request: 'request-a-14' },
        { source_asset: '2-well-N3', target_asset: '4-well-G2', outer_request: 'request-b-14' },
        { source_asset: '2-well-O3', target_asset: '3-well-H2', outer_request: 'request-a-15' },
        { source_asset: '2-well-P3', target_asset: '4-well-H2', outer_request: 'request-b-15' },
        { source_asset: '2-well-A4', target_asset: '5-well-A2', outer_request: 'request-c-8' },
        { source_asset: '2-well-B4', target_asset: '6-well-A2', outer_request: 'request-d-8' },
        { source_asset: '2-well-C4', target_asset: '5-well-B2', outer_request: 'request-c-9' },
        { source_asset: '2-well-D4', target_asset: '6-well-B2', outer_request: 'request-d-9' },
        { source_asset: '2-well-E4', target_asset: '5-well-C2', outer_request: 'request-c-10' },
        { source_asset: '2-well-F4', target_asset: '6-well-C2', outer_request: 'request-d-10' },
        { source_asset: '2-well-G4', target_asset: '5-well-D2', outer_request: 'request-c-11' },
        { source_asset: '2-well-H4', target_asset: '6-well-D2', outer_request: 'request-d-11' },
        { source_asset: '2-well-I4', target_asset: '5-well-E2', outer_request: 'request-c-12' },
        { source_asset: '2-well-J4', target_asset: '6-well-E2', outer_request: 'request-d-12' },
        { source_asset: '2-well-K4', target_asset: '5-well-F2', outer_request: 'request-c-13' },
        { source_asset: '2-well-L4', target_asset: '6-well-F2', outer_request: 'request-d-13' },
        { source_asset: '2-well-M4', target_asset: '5-well-G2', outer_request: 'request-c-14' },
        { source_asset: '2-well-N4', target_asset: '6-well-G2', outer_request: 'request-d-14' },
        { source_asset: '2-well-O4', target_asset: '5-well-H2', outer_request: 'request-c-15' },
        { source_asset: '2-well-P4', target_asset: '6-well-H2', outer_request: 'request-d-15' },
        { source_asset: '2-well-A5', target_asset: '3-well-A3', outer_request: 'request-a-16' },
        { source_asset: '2-well-B5', target_asset: '4-well-A3', outer_request: 'request-b-16' },
        { source_asset: '2-well-C5', target_asset: '3-well-B3', outer_request: 'request-a-17' },
        { source_asset: '2-well-D5', target_asset: '4-well-B3', outer_request: 'request-b-17' },
        { source_asset: '2-well-E5', target_asset: '3-well-C3', outer_request: 'request-a-18' },
        { source_asset: '2-well-F5', target_asset: '4-well-C3', outer_request: 'request-b-18' },
        { source_asset: '2-well-G5', target_asset: '3-well-D3', outer_request: 'request-a-19' },
        { source_asset: '2-well-H5', target_asset: '4-well-D3', outer_request: 'request-b-19' },
        { source_asset: '2-well-I5', target_asset: '3-well-E3', outer_request: 'request-a-20' },
        { source_asset: '2-well-J5', target_asset: '4-well-E3', outer_request: 'request-b-20' },
        { source_asset: '2-well-K5', target_asset: '3-well-F3', outer_request: 'request-a-21' },
        { source_asset: '2-well-L5', target_asset: '4-well-F3', outer_request: 'request-b-21' },
        { source_asset: '2-well-M5', target_asset: '3-well-G3', outer_request: 'request-a-22' },
        { source_asset: '2-well-N5', target_asset: '4-well-G3', outer_request: 'request-b-22' },
        { source_asset: '2-well-O5', target_asset: '3-well-H3', outer_request: 'request-a-23' },
        { source_asset: '2-well-P5', target_asset: '4-well-H3', outer_request: 'request-b-23' },
        { source_asset: '2-well-A6', target_asset: '5-well-A3', outer_request: 'request-c-16' },
        { source_asset: '2-well-B6', target_asset: '6-well-A3', outer_request: 'request-d-16' },
        { source_asset: '2-well-C6', target_asset: '5-well-B3', outer_request: 'request-c-17' },
        { source_asset: '2-well-D6', target_asset: '6-well-B3', outer_request: 'request-d-17' },
        { source_asset: '2-well-E6', target_asset: '5-well-C3', outer_request: 'request-c-18' },
        { source_asset: '2-well-F6', target_asset: '6-well-C3', outer_request: 'request-d-18' },
        { source_asset: '2-well-G6', target_asset: '5-well-D3', outer_request: 'request-c-19' },
        { source_asset: '2-well-H6', target_asset: '6-well-D3', outer_request: 'request-d-19' },
        { source_asset: '2-well-I6', target_asset: '5-well-E3', outer_request: 'request-c-20' },
        { source_asset: '2-well-J6', target_asset: '6-well-E3', outer_request: 'request-d-20' },
        { source_asset: '2-well-K6', target_asset: '5-well-F3', outer_request: 'request-c-21' },
        { source_asset: '2-well-L6', target_asset: '6-well-F3', outer_request: 'request-d-21' },
        { source_asset: '2-well-M6', target_asset: '5-well-G3', outer_request: 'request-c-22' },
        { source_asset: '2-well-N6', target_asset: '6-well-G3', outer_request: 'request-d-22' },
        { source_asset: '2-well-O6', target_asset: '5-well-H3', outer_request: 'request-c-23' },
        { source_asset: '2-well-P6', target_asset: '6-well-H3', outer_request: 'request-d-23' },
        { source_asset: '2-well-A7', target_asset: '3-well-A4', outer_request: 'request-a-24' },
        { source_asset: '2-well-B7', target_asset: '4-well-A4', outer_request: 'request-b-24' },
        { source_asset: '2-well-C7', target_asset: '3-well-B4', outer_request: 'request-a-25' },
        { source_asset: '2-well-D7', target_asset: '4-well-B4', outer_request: 'request-b-25' },
        { source_asset: '2-well-E7', target_asset: '3-well-C4', outer_request: 'request-a-26' },
        { source_asset: '2-well-F7', target_asset: '4-well-C4', outer_request: 'request-b-26' },
        { source_asset: '2-well-G7', target_asset: '3-well-D4', outer_request: 'request-a-27' },
        { source_asset: '2-well-H7', target_asset: '4-well-D4', outer_request: 'request-b-27' },
        { source_asset: '2-well-I7', target_asset: '3-well-E4', outer_request: 'request-a-28' },
        { source_asset: '2-well-J7', target_asset: '4-well-E4', outer_request: 'request-b-28' },
        { source_asset: '2-well-K7', target_asset: '3-well-F4', outer_request: 'request-a-29' },
        { source_asset: '2-well-L7', target_asset: '4-well-F4', outer_request: 'request-b-29' },
        { source_asset: '2-well-M7', target_asset: '3-well-G4', outer_request: 'request-a-30' },
        { source_asset: '2-well-N7', target_asset: '4-well-G4', outer_request: 'request-b-30' },
        { source_asset: '2-well-O7', target_asset: '3-well-H4', outer_request: 'request-a-31' },
        { source_asset: '2-well-P7', target_asset: '4-well-H4', outer_request: 'request-b-31' },
        { source_asset: '2-well-A8', target_asset: '5-well-A4', outer_request: 'request-c-24' },
        { source_asset: '2-well-B8', target_asset: '6-well-A4', outer_request: 'request-d-24' },
        { source_asset: '2-well-C8', target_asset: '5-well-B4', outer_request: 'request-c-25' },
        { source_asset: '2-well-D8', target_asset: '6-well-B4', outer_request: 'request-d-25' },
        { source_asset: '2-well-E8', target_asset: '5-well-C4', outer_request: 'request-c-26' },
        { source_asset: '2-well-F8', target_asset: '6-well-C4', outer_request: 'request-d-26' },
        { source_asset: '2-well-G8', target_asset: '5-well-D4', outer_request: 'request-c-27' },
        { source_asset: '2-well-H8', target_asset: '6-well-D4', outer_request: 'request-d-27' },
        { source_asset: '2-well-I8', target_asset: '5-well-E4', outer_request: 'request-c-28' },
        { source_asset: '2-well-J8', target_asset: '6-well-E4', outer_request: 'request-d-28' },
        { source_asset: '2-well-K8', target_asset: '5-well-F4', outer_request: 'request-c-29' },
        { source_asset: '2-well-L8', target_asset: '6-well-F4', outer_request: 'request-d-29' },
        { source_asset: '2-well-M8', target_asset: '5-well-G4', outer_request: 'request-c-30' },
        { source_asset: '2-well-N8', target_asset: '6-well-G4', outer_request: 'request-d-30' },
        { source_asset: '2-well-O8', target_asset: '5-well-H4', outer_request: 'request-c-31' },
        { source_asset: '2-well-P8', target_asset: '6-well-H4', outer_request: 'request-d-31' },
        { source_asset: '2-well-A9', target_asset: '3-well-A5', outer_request: 'request-a-32' },
        { source_asset: '2-well-B9', target_asset: '4-well-A5', outer_request: 'request-b-32' },
        { source_asset: '2-well-C9', target_asset: '3-well-B5', outer_request: 'request-a-33' },
        { source_asset: '2-well-D9', target_asset: '4-well-B5', outer_request: 'request-b-33' },
        { source_asset: '2-well-E9', target_asset: '3-well-C5', outer_request: 'request-a-34' },
        { source_asset: '2-well-F9', target_asset: '4-well-C5', outer_request: 'request-b-34' },
        { source_asset: '2-well-G9', target_asset: '3-well-D5', outer_request: 'request-a-35' },
        { source_asset: '2-well-H9', target_asset: '4-well-D5', outer_request: 'request-b-35' },
        { source_asset: '2-well-I9', target_asset: '3-well-E5', outer_request: 'request-a-36' },
        { source_asset: '2-well-J9', target_asset: '4-well-E5', outer_request: 'request-b-36' },
        { source_asset: '2-well-K9', target_asset: '3-well-F5', outer_request: 'request-a-37' },
        { source_asset: '2-well-L9', target_asset: '4-well-F5', outer_request: 'request-b-37' },
        { source_asset: '2-well-M9', target_asset: '3-well-G5', outer_request: 'request-a-38' },
        { source_asset: '2-well-N9', target_asset: '4-well-G5', outer_request: 'request-b-38' },
        { source_asset: '2-well-O9', target_asset: '3-well-H5', outer_request: 'request-a-39' },
        { source_asset: '2-well-P9', target_asset: '4-well-H5', outer_request: 'request-b-39' },
        { source_asset: '2-well-A10', target_asset: '5-well-A5', outer_request: 'request-c-32' },
        { source_asset: '2-well-B10', target_asset: '6-well-A5', outer_request: 'request-d-32' },
        { source_asset: '2-well-C10', target_asset: '5-well-B5', outer_request: 'request-c-33' },
        { source_asset: '2-well-D10', target_asset: '6-well-B5', outer_request: 'request-d-33' },
        { source_asset: '2-well-E10', target_asset: '5-well-C5', outer_request: 'request-c-34' },
        { source_asset: '2-well-F10', target_asset: '6-well-C5', outer_request: 'request-d-34' },
        { source_asset: '2-well-G10', target_asset: '5-well-D5', outer_request: 'request-c-35' },
        { source_asset: '2-well-H10', target_asset: '6-well-D5', outer_request: 'request-d-35' },
        { source_asset: '2-well-I10', target_asset: '5-well-E5', outer_request: 'request-c-36' },
        { source_asset: '2-well-J10', target_asset: '6-well-E5', outer_request: 'request-d-36' },
        { source_asset: '2-well-K10', target_asset: '5-well-F5', outer_request: 'request-c-37' },
        { source_asset: '2-well-L10', target_asset: '6-well-F5', outer_request: 'request-d-37' },
        { source_asset: '2-well-M10', target_asset: '5-well-G5', outer_request: 'request-c-38' },
        { source_asset: '2-well-N10', target_asset: '6-well-G5', outer_request: 'request-d-38' },
        { source_asset: '2-well-O10', target_asset: '5-well-H5', outer_request: 'request-c-39' },
        { source_asset: '2-well-P10', target_asset: '6-well-H5', outer_request: 'request-d-39' },
        { source_asset: '2-well-A11', target_asset: '3-well-A6', outer_request: 'request-a-40' },
        { source_asset: '2-well-B11', target_asset: '4-well-A6', outer_request: 'request-b-40' },
        { source_asset: '2-well-C11', target_asset: '3-well-B6', outer_request: 'request-a-41' },
        { source_asset: '2-well-D11', target_asset: '4-well-B6', outer_request: 'request-b-41' },
        { source_asset: '2-well-E11', target_asset: '3-well-C6', outer_request: 'request-a-42' },
        { source_asset: '2-well-F11', target_asset: '4-well-C6', outer_request: 'request-b-42' },
        { source_asset: '2-well-G11', target_asset: '3-well-D6', outer_request: 'request-a-43' },
        { source_asset: '2-well-H11', target_asset: '4-well-D6', outer_request: 'request-b-43' },
        { source_asset: '2-well-I11', target_asset: '3-well-E6', outer_request: 'request-a-44' },
        { source_asset: '2-well-J11', target_asset: '4-well-E6', outer_request: 'request-b-44' },
        { source_asset: '2-well-K11', target_asset: '3-well-F6', outer_request: 'request-a-45' },
        { source_asset: '2-well-L11', target_asset: '4-well-F6', outer_request: 'request-b-45' },
        { source_asset: '2-well-M11', target_asset: '3-well-G6', outer_request: 'request-a-46' },
        { source_asset: '2-well-N11', target_asset: '4-well-G6', outer_request: 'request-b-46' },
        { source_asset: '2-well-O11', target_asset: '3-well-H6', outer_request: 'request-a-47' },
        { source_asset: '2-well-P11', target_asset: '4-well-H6', outer_request: 'request-b-47' },
        { source_asset: '2-well-A12', target_asset: '5-well-A6', outer_request: 'request-c-40' },
        { source_asset: '2-well-B12', target_asset: '6-well-A6', outer_request: 'request-d-40' },
        { source_asset: '2-well-C12', target_asset: '5-well-B6', outer_request: 'request-c-41' },
        { source_asset: '2-well-D12', target_asset: '6-well-B6', outer_request: 'request-d-41' },
        { source_asset: '2-well-E12', target_asset: '5-well-C6', outer_request: 'request-c-42' },
        { source_asset: '2-well-F12', target_asset: '6-well-C6', outer_request: 'request-d-42' },
        { source_asset: '2-well-G12', target_asset: '5-well-D6', outer_request: 'request-c-43' },
        { source_asset: '2-well-H12', target_asset: '6-well-D6', outer_request: 'request-d-43' },
        { source_asset: '2-well-I12', target_asset: '5-well-E6', outer_request: 'request-c-44' },
        { source_asset: '2-well-J12', target_asset: '6-well-E6', outer_request: 'request-d-44' },
        { source_asset: '2-well-K12', target_asset: '5-well-F6', outer_request: 'request-c-45' },
        { source_asset: '2-well-L12', target_asset: '6-well-F6', outer_request: 'request-d-45' },
        { source_asset: '2-well-M12', target_asset: '5-well-G6', outer_request: 'request-c-46' },
        { source_asset: '2-well-N12', target_asset: '6-well-G6', outer_request: 'request-d-46' },
        { source_asset: '2-well-O12', target_asset: '5-well-H6', outer_request: 'request-c-47' },
        { source_asset: '2-well-P12', target_asset: '6-well-H6', outer_request: 'request-d-47' },
        { source_asset: '2-well-A13', target_asset: '3-well-A7', outer_request: 'request-a-48' },
        { source_asset: '2-well-B13', target_asset: '4-well-A7', outer_request: 'request-b-48' },
        { source_asset: '2-well-C13', target_asset: '3-well-B7', outer_request: 'request-a-49' },
        { source_asset: '2-well-D13', target_asset: '4-well-B7', outer_request: 'request-b-49' },
        { source_asset: '2-well-E13', target_asset: '3-well-C7', outer_request: 'request-a-50' },
        { source_asset: '2-well-F13', target_asset: '4-well-C7', outer_request: 'request-b-50' },
        { source_asset: '2-well-G13', target_asset: '3-well-D7', outer_request: 'request-a-51' },
        { source_asset: '2-well-H13', target_asset: '4-well-D7', outer_request: 'request-b-51' },
        { source_asset: '2-well-I13', target_asset: '3-well-E7', outer_request: 'request-a-52' },
        { source_asset: '2-well-J13', target_asset: '4-well-E7', outer_request: 'request-b-52' },
        { source_asset: '2-well-K13', target_asset: '3-well-F7', outer_request: 'request-a-53' },
        { source_asset: '2-well-L13', target_asset: '4-well-F7', outer_request: 'request-b-53' },
        { source_asset: '2-well-M13', target_asset: '3-well-G7', outer_request: 'request-a-54' },
        { source_asset: '2-well-N13', target_asset: '4-well-G7', outer_request: 'request-b-54' },
        { source_asset: '2-well-O13', target_asset: '3-well-H7', outer_request: 'request-a-55' },
        { source_asset: '2-well-P13', target_asset: '4-well-H7', outer_request: 'request-b-55' },
        { source_asset: '2-well-A14', target_asset: '5-well-A7', outer_request: 'request-c-48' },
        { source_asset: '2-well-B14', target_asset: '6-well-A7', outer_request: 'request-d-48' },
        { source_asset: '2-well-C14', target_asset: '5-well-B7', outer_request: 'request-c-49' },
        { source_asset: '2-well-D14', target_asset: '6-well-B7', outer_request: 'request-d-49' },
        { source_asset: '2-well-E14', target_asset: '5-well-C7', outer_request: 'request-c-50' },
        { source_asset: '2-well-F14', target_asset: '6-well-C7', outer_request: 'request-d-50' },
        { source_asset: '2-well-G14', target_asset: '5-well-D7', outer_request: 'request-c-51' },
        { source_asset: '2-well-H14', target_asset: '6-well-D7', outer_request: 'request-d-51' },
        { source_asset: '2-well-I14', target_asset: '5-well-E7', outer_request: 'request-c-52' },
        { source_asset: '2-well-J14', target_asset: '6-well-E7', outer_request: 'request-d-52' },
        { source_asset: '2-well-K14', target_asset: '5-well-F7', outer_request: 'request-c-53' },
        { source_asset: '2-well-L14', target_asset: '6-well-F7', outer_request: 'request-d-53' },
        { source_asset: '2-well-M14', target_asset: '5-well-G7', outer_request: 'request-c-54' },
        { source_asset: '2-well-N14', target_asset: '6-well-G7', outer_request: 'request-d-54' },
        { source_asset: '2-well-O14', target_asset: '5-well-H7', outer_request: 'request-c-55' },
        { source_asset: '2-well-P14', target_asset: '6-well-H7', outer_request: 'request-d-55' },
        { source_asset: '2-well-A15', target_asset: '3-well-A8', outer_request: 'request-a-56' },
        { source_asset: '2-well-B15', target_asset: '4-well-A8', outer_request: 'request-b-56' },
        { source_asset: '2-well-C15', target_asset: '3-well-B8', outer_request: 'request-a-57' },
        { source_asset: '2-well-D15', target_asset: '4-well-B8', outer_request: 'request-b-57' },
        { source_asset: '2-well-E15', target_asset: '3-well-C8', outer_request: 'request-a-58' },
        { source_asset: '2-well-F15', target_asset: '4-well-C8', outer_request: 'request-b-58' },
        { source_asset: '2-well-G15', target_asset: '3-well-D8', outer_request: 'request-a-59' },
        { source_asset: '2-well-H15', target_asset: '4-well-D8', outer_request: 'request-b-59' },
        { source_asset: '2-well-I15', target_asset: '3-well-E8', outer_request: 'request-a-60' },
        { source_asset: '2-well-J15', target_asset: '4-well-E8', outer_request: 'request-b-60' },
        { source_asset: '2-well-K15', target_asset: '3-well-F8', outer_request: 'request-a-61' },
        { source_asset: '2-well-L15', target_asset: '4-well-F8', outer_request: 'request-b-61' },
        { source_asset: '2-well-M15', target_asset: '3-well-G8', outer_request: 'request-a-62' },
        { source_asset: '2-well-N15', target_asset: '4-well-G8', outer_request: 'request-b-62' },
        { source_asset: '2-well-O15', target_asset: '3-well-H8', outer_request: 'request-a-63' },
        { source_asset: '2-well-P15', target_asset: '4-well-H8', outer_request: 'request-b-63' },
        { source_asset: '2-well-A16', target_asset: '5-well-A8', outer_request: 'request-c-56' },
        { source_asset: '2-well-B16', target_asset: '6-well-A8', outer_request: 'request-d-56' },
        { source_asset: '2-well-C16', target_asset: '5-well-B8', outer_request: 'request-c-57' },
        { source_asset: '2-well-D16', target_asset: '6-well-B8', outer_request: 'request-d-57' },
        { source_asset: '2-well-E16', target_asset: '5-well-C8', outer_request: 'request-c-58' },
        { source_asset: '2-well-F16', target_asset: '6-well-C8', outer_request: 'request-d-58' },
        { source_asset: '2-well-G16', target_asset: '5-well-D8', outer_request: 'request-c-59' },
        { source_asset: '2-well-H16', target_asset: '6-well-D8', outer_request: 'request-d-59' },
        { source_asset: '2-well-I16', target_asset: '5-well-E8', outer_request: 'request-c-60' },
        { source_asset: '2-well-J16', target_asset: '6-well-E8', outer_request: 'request-d-60' },
        { source_asset: '2-well-K16', target_asset: '5-well-F8', outer_request: 'request-c-61' },
        { source_asset: '2-well-L16', target_asset: '6-well-F8', outer_request: 'request-d-61' },
        { source_asset: '2-well-M16', target_asset: '5-well-G8', outer_request: 'request-c-62' },
        { source_asset: '2-well-N16', target_asset: '6-well-G8', outer_request: 'request-d-62' },
        { source_asset: '2-well-O16', target_asset: '5-well-H8', outer_request: 'request-c-63' },
        { source_asset: '2-well-P16', target_asset: '6-well-H8', outer_request: 'request-d-63' },
        { source_asset: '2-well-A17', target_asset: '3-well-A9', outer_request: 'request-a-64' },
        { source_asset: '2-well-B17', target_asset: '4-well-A9', outer_request: 'request-b-64' },
        { source_asset: '2-well-C17', target_asset: '3-well-B9', outer_request: 'request-a-65' },
        { source_asset: '2-well-D17', target_asset: '4-well-B9', outer_request: 'request-b-65' },
        { source_asset: '2-well-E17', target_asset: '3-well-C9', outer_request: 'request-a-66' },
        { source_asset: '2-well-F17', target_asset: '4-well-C9', outer_request: 'request-b-66' },
        { source_asset: '2-well-G17', target_asset: '3-well-D9', outer_request: 'request-a-67' },
        { source_asset: '2-well-H17', target_asset: '4-well-D9', outer_request: 'request-b-67' },
        { source_asset: '2-well-I17', target_asset: '3-well-E9', outer_request: 'request-a-68' },
        { source_asset: '2-well-J17', target_asset: '4-well-E9', outer_request: 'request-b-68' },
        { source_asset: '2-well-K17', target_asset: '3-well-F9', outer_request: 'request-a-69' },
        { source_asset: '2-well-L17', target_asset: '4-well-F9', outer_request: 'request-b-69' },
        { source_asset: '2-well-M17', target_asset: '3-well-G9', outer_request: 'request-a-70' },
        { source_asset: '2-well-N17', target_asset: '4-well-G9', outer_request: 'request-b-70' },
        { source_asset: '2-well-O17', target_asset: '3-well-H9', outer_request: 'request-a-71' },
        { source_asset: '2-well-P17', target_asset: '4-well-H9', outer_request: 'request-b-71' },
        { source_asset: '2-well-A18', target_asset: '5-well-A9', outer_request: 'request-c-64' },
        { source_asset: '2-well-B18', target_asset: '6-well-A9', outer_request: 'request-d-64' },
        { source_asset: '2-well-C18', target_asset: '5-well-B9', outer_request: 'request-c-65' },
        { source_asset: '2-well-D18', target_asset: '6-well-B9', outer_request: 'request-d-65' },
        { source_asset: '2-well-E18', target_asset: '5-well-C9', outer_request: 'request-c-66' },
        { source_asset: '2-well-F18', target_asset: '6-well-C9', outer_request: 'request-d-66' },
        { source_asset: '2-well-G18', target_asset: '5-well-D9', outer_request: 'request-c-67' },
        { source_asset: '2-well-H18', target_asset: '6-well-D9', outer_request: 'request-d-67' },
        { source_asset: '2-well-I18', target_asset: '5-well-E9', outer_request: 'request-c-68' },
        { source_asset: '2-well-J18', target_asset: '6-well-E9', outer_request: 'request-d-68' },
        { source_asset: '2-well-K18', target_asset: '5-well-F9', outer_request: 'request-c-69' },
        { source_asset: '2-well-L18', target_asset: '6-well-F9', outer_request: 'request-d-69' },
        { source_asset: '2-well-M18', target_asset: '5-well-G9', outer_request: 'request-c-70' },
        { source_asset: '2-well-N18', target_asset: '6-well-G9', outer_request: 'request-d-70' },
        { source_asset: '2-well-O18', target_asset: '5-well-H9', outer_request: 'request-c-71' },
        { source_asset: '2-well-P18', target_asset: '6-well-H9', outer_request: 'request-d-71' },
        { source_asset: '2-well-A19', target_asset: '3-well-A10', outer_request: 'request-a-72' },
        { source_asset: '2-well-B19', target_asset: '4-well-A10', outer_request: 'request-b-72' },
        { source_asset: '2-well-C19', target_asset: '3-well-B10', outer_request: 'request-a-73' },
        { source_asset: '2-well-D19', target_asset: '4-well-B10', outer_request: 'request-b-73' },
        { source_asset: '2-well-E19', target_asset: '3-well-C10', outer_request: 'request-a-74' },
        { source_asset: '2-well-F19', target_asset: '4-well-C10', outer_request: 'request-b-74' },
        { source_asset: '2-well-G19', target_asset: '3-well-D10', outer_request: 'request-a-75' },
        { source_asset: '2-well-H19', target_asset: '4-well-D10', outer_request: 'request-b-75' },
        { source_asset: '2-well-I19', target_asset: '3-well-E10', outer_request: 'request-a-76' },
        { source_asset: '2-well-J19', target_asset: '4-well-E10', outer_request: 'request-b-76' },
        { source_asset: '2-well-K19', target_asset: '3-well-F10', outer_request: 'request-a-77' },
        { source_asset: '2-well-L19', target_asset: '4-well-F10', outer_request: 'request-b-77' },
        { source_asset: '2-well-M19', target_asset: '3-well-G10', outer_request: 'request-a-78' },
        { source_asset: '2-well-N19', target_asset: '4-well-G10', outer_request: 'request-b-78' },
        { source_asset: '2-well-O19', target_asset: '3-well-H10', outer_request: 'request-a-79' },
        { source_asset: '2-well-P19', target_asset: '4-well-H10', outer_request: 'request-b-79' },
        { source_asset: '2-well-A20', target_asset: '5-well-A10', outer_request: 'request-c-72' },
        { source_asset: '2-well-B20', target_asset: '6-well-A10', outer_request: 'request-d-72' },
        { source_asset: '2-well-C20', target_asset: '5-well-B10', outer_request: 'request-c-73' },
        { source_asset: '2-well-D20', target_asset: '6-well-B10', outer_request: 'request-d-73' },
        { source_asset: '2-well-E20', target_asset: '5-well-C10', outer_request: 'request-c-74' },
        { source_asset: '2-well-F20', target_asset: '6-well-C10', outer_request: 'request-d-74' },
        { source_asset: '2-well-G20', target_asset: '5-well-D10', outer_request: 'request-c-75' },
        { source_asset: '2-well-H20', target_asset: '6-well-D10', outer_request: 'request-d-75' },
        { source_asset: '2-well-I20', target_asset: '5-well-E10', outer_request: 'request-c-76' },
        { source_asset: '2-well-J20', target_asset: '6-well-E10', outer_request: 'request-d-76' },
        { source_asset: '2-well-K20', target_asset: '5-well-F10', outer_request: 'request-c-77' },
        { source_asset: '2-well-L20', target_asset: '6-well-F10', outer_request: 'request-d-77' },
        { source_asset: '2-well-M20', target_asset: '5-well-G10', outer_request: 'request-c-78' },
        { source_asset: '2-well-N20', target_asset: '6-well-G10', outer_request: 'request-d-78' },
        { source_asset: '2-well-O20', target_asset: '5-well-H10', outer_request: 'request-c-79' },
        { source_asset: '2-well-P20', target_asset: '6-well-H10', outer_request: 'request-d-79' },
        { source_asset: '2-well-A21', target_asset: '3-well-A11', outer_request: 'request-a-80' },
        { source_asset: '2-well-B21', target_asset: '4-well-A11', outer_request: 'request-b-80' },
        { source_asset: '2-well-C21', target_asset: '3-well-B11', outer_request: 'request-a-81' },
        { source_asset: '2-well-D21', target_asset: '4-well-B11', outer_request: 'request-b-81' },
        { source_asset: '2-well-E21', target_asset: '3-well-C11', outer_request: 'request-a-82' },
        { source_asset: '2-well-F21', target_asset: '4-well-C11', outer_request: 'request-b-82' },
        { source_asset: '2-well-G21', target_asset: '3-well-D11', outer_request: 'request-a-83' },
        { source_asset: '2-well-H21', target_asset: '4-well-D11', outer_request: 'request-b-83' },
        { source_asset: '2-well-I21', target_asset: '3-well-E11', outer_request: 'request-a-84' },
        { source_asset: '2-well-J21', target_asset: '4-well-E11', outer_request: 'request-b-84' },
        { source_asset: '2-well-K21', target_asset: '3-well-F11', outer_request: 'request-a-85' },
        { source_asset: '2-well-L21', target_asset: '4-well-F11', outer_request: 'request-b-85' },
        { source_asset: '2-well-M21', target_asset: '3-well-G11', outer_request: 'request-a-86' },
        { source_asset: '2-well-N21', target_asset: '4-well-G11', outer_request: 'request-b-86' },
        { source_asset: '2-well-O21', target_asset: '3-well-H11', outer_request: 'request-a-87' },
        { source_asset: '2-well-P21', target_asset: '4-well-H11', outer_request: 'request-b-87' },
        { source_asset: '2-well-A22', target_asset: '5-well-A11', outer_request: 'request-c-80' },
        { source_asset: '2-well-B22', target_asset: '6-well-A11', outer_request: 'request-d-80' },
        { source_asset: '2-well-C22', target_asset: '5-well-B11', outer_request: 'request-c-81' },
        { source_asset: '2-well-D22', target_asset: '6-well-B11', outer_request: 'request-d-81' },
        { source_asset: '2-well-E22', target_asset: '5-well-C11', outer_request: 'request-c-82' },
        { source_asset: '2-well-F22', target_asset: '6-well-C11', outer_request: 'request-d-82' },
        { source_asset: '2-well-G22', target_asset: '5-well-D11', outer_request: 'request-c-83' },
        { source_asset: '2-well-H22', target_asset: '6-well-D11', outer_request: 'request-d-83' },
        { source_asset: '2-well-I22', target_asset: '5-well-E11', outer_request: 'request-c-84' },
        { source_asset: '2-well-J22', target_asset: '6-well-E11', outer_request: 'request-d-84' },
        { source_asset: '2-well-K22', target_asset: '5-well-F11', outer_request: 'request-c-85' },
        { source_asset: '2-well-L22', target_asset: '6-well-F11', outer_request: 'request-d-85' },
        { source_asset: '2-well-M22', target_asset: '5-well-G11', outer_request: 'request-c-86' },
        { source_asset: '2-well-N22', target_asset: '6-well-G11', outer_request: 'request-d-86' },
        { source_asset: '2-well-O22', target_asset: '5-well-H11', outer_request: 'request-c-87' },
        { source_asset: '2-well-P22', target_asset: '6-well-H11', outer_request: 'request-d-87' },
        { source_asset: '2-well-A23', target_asset: '3-well-A12', outer_request: 'request-a-88' },
        { source_asset: '2-well-B23', target_asset: '4-well-A12', outer_request: 'request-b-88' },
        { source_asset: '2-well-C23', target_asset: '3-well-B12', outer_request: 'request-a-89' },
        { source_asset: '2-well-D23', target_asset: '4-well-B12', outer_request: 'request-b-89' },
        { source_asset: '2-well-E23', target_asset: '3-well-C12', outer_request: 'request-a-90' },
        { source_asset: '2-well-F23', target_asset: '4-well-C12', outer_request: 'request-b-90' },
        { source_asset: '2-well-G23', target_asset: '3-well-D12', outer_request: 'request-a-91' },
        { source_asset: '2-well-H23', target_asset: '4-well-D12', outer_request: 'request-b-91' },
        { source_asset: '2-well-I23', target_asset: '3-well-E12', outer_request: 'request-a-92' },
        { source_asset: '2-well-J23', target_asset: '4-well-E12', outer_request: 'request-b-92' },
        { source_asset: '2-well-K23', target_asset: '3-well-F12', outer_request: 'request-a-93' },
        { source_asset: '2-well-L23', target_asset: '4-well-F12', outer_request: 'request-b-93' },
        { source_asset: '2-well-M23', target_asset: '3-well-G12', outer_request: 'request-a-94' },
        { source_asset: '2-well-N23', target_asset: '4-well-G12', outer_request: 'request-b-94' },
        { source_asset: '2-well-O23', target_asset: '3-well-H12', outer_request: 'request-a-95' },
        { source_asset: '2-well-P23', target_asset: '4-well-H12', outer_request: 'request-b-95' },
        { source_asset: '2-well-A24', target_asset: '5-well-A12', outer_request: 'request-c-88' },
        { source_asset: '2-well-B24', target_asset: '6-well-A12', outer_request: 'request-d-88' },
        { source_asset: '2-well-C24', target_asset: '5-well-B12', outer_request: 'request-c-89' },
        { source_asset: '2-well-D24', target_asset: '6-well-B12', outer_request: 'request-d-89' },
        { source_asset: '2-well-E24', target_asset: '5-well-C12', outer_request: 'request-c-90' },
        { source_asset: '2-well-F24', target_asset: '6-well-C12', outer_request: 'request-d-90' },
        { source_asset: '2-well-G24', target_asset: '5-well-D12', outer_request: 'request-c-91' },
        { source_asset: '2-well-H24', target_asset: '6-well-D12', outer_request: 'request-d-91' },
        { source_asset: '2-well-I24', target_asset: '5-well-E12', outer_request: 'request-c-92' },
        { source_asset: '2-well-J24', target_asset: '6-well-E12', outer_request: 'request-d-92' },
        { source_asset: '2-well-K24', target_asset: '5-well-F12', outer_request: 'request-c-93' },
        { source_asset: '2-well-L24', target_asset: '6-well-F12', outer_request: 'request-d-93' },
        { source_asset: '2-well-M24', target_asset: '5-well-G12', outer_request: 'request-c-94' },
        { source_asset: '2-well-N24', target_asset: '6-well-G12', outer_request: 'request-d-94' },
        { source_asset: '2-well-O24', target_asset: '5-well-H12', outer_request: 'request-c-95' },
        { source_asset: '2-well-P24', target_asset: '6-well-H12', outer_request: 'request-d-95' }
      ]
    end

    it_behaves_like 'a quad-split plate creator'
  end
end
