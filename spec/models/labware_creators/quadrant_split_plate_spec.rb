# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Splits one 384 well plate into 4x96 well plates
RSpec.describe LabwareCreators::QuadrantSplitPlate do
  include FeatureHelpers

  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  let(:user) { create :user }
  let(:user_uuid) { user.uuid }

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:parent_plate_size) { 384 }

  let(:child_plate_size) { 96 }
  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:stock_plate_uuid) { 'stock-plate-uuid' }
  let(:stock_purpose_name) { 'Merger Plate Purpose' }
  let(:stock_plate_barcode) { 1 }

  let(:stock_plate) do
    create(
      :stock_plate_for_plate,
      purpose_name: stock_purpose_name,
      barcode_number: stock_plate_barcode,
      uuid: stock_plate_uuid
    )
  end

  let(:quad_a_requests) { create_list :library_request, parent_plate_size, state: 'started', submission_id: 1 }
  let(:quad_b_requests) { create_list :library_request, parent_plate_size, state: 'started', submission_id: 2 }
  let(:quad_c_requests) { create_list :library_request, parent_plate_size, state: 'started', submission_id: 3 }
  let(:quad_d_requests) { create_list :library_request, parent_plate_size, state: 'started', submission_id: 4 }

  let(:requests) do
    quads = [[quad_a_requests, quad_c_requests], [quad_b_requests, quad_d_requests]]
    Array.new(384) do |i|
      row = i % 16
      col = i / 16
      quad = quads[row % 2][col % 2]
      index = (row / 2) + (8 * (col / 2))
      quad[index]
    end
  end

  let(:plate) do
    create(
      :plate,
      uuid: parent_uuid,
      stock_plate: stock_plate,
      barcode_number: '2',
      size: parent_plate_size,
      outer_requests: requests
    )
  end

  let(:child_plate_a) do
    create(
      :plate,
      uuid: 'child-a-uuid',
      barcode_number: '3',
      size: child_plate_size,
      outer_requests: quad_a_requests
    )
  end
  let(:child_plate_a_create_args) do
    { user_id: user.id, asset_id: child_plate_a.id, metadata: { stock_barcode: "* #{child_plate_a.barcode.machine}" } }
  end

  let(:child_plate_b) do
    create(
      :plate,
      uuid: 'child-b-uuid',
      barcode_number: '4',
      size: child_plate_size,
      outer_requests: quad_b_requests
    )
  end
  let(:child_plate_b_create_args) do
    { user_id: user.id, asset_id: child_plate_b.id, metadata: { stock_barcode: "* #{child_plate_b.barcode.machine}" } }
  end

  let(:child_plate_c) do
    create(
      :plate,
      uuid: 'child-c-uuid',
      barcode_number: '5',
      size: child_plate_size,
      outer_requests: quad_c_requests
    )
  end
  let(:child_plate_c_create_args) do
    { user_id: user.id, asset_id: child_plate_c.id, metadata: { stock_barcode: "* #{child_plate_c.barcode.machine}" } }
  end

  let(:child_plate_d) do
    create(
      :plate,
      uuid: 'child-d-uuid',
      barcode_number: '6',
      size: child_plate_size,
      outer_requests: quad_d_requests
    )
  end
  let(:child_plate_d_create_args) do
    { user_id: user.id, asset_id: child_plate_d.id, metadata: { stock_barcode: "* #{child_plate_d.barcode.machine}" } }
  end

  before do
    create(:purpose_config, name: child_purpose_name, uuid: child_purpose_uuid)
    allow(Sequencescape::Api::V2::Plate).to receive(:find_all).with(
      { uuid: %w[child-a-uuid child-b-uuid child-c-uuid child-d-uuid] },
      includes: ['wells']
    ).and_return([child_plate_a, child_plate_b, child_plate_c, child_plate_d])
    stub_plate(plate, stub_search: false)
  end

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a described_class
    end
  end

  shared_examples 'a quad-split plate creator' do
    describe '#save!' do
      let(:custom_metadatum_collections_attributes) do
        [child_plate_a_create_args, child_plate_b_create_args, child_plate_c_create_args, child_plate_d_create_args]
      end

      let(:plate_creations_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] * 4 }

      before do
        allow(SearchHelper).to receive(:merger_plate_names).and_return(stock_purpose_name)

        stub_user(user)

        stub_labware(stock_plate)
        stub_labware(child_plate_a)
        stub_labware(child_plate_b)
        stub_labware(child_plate_c)
        stub_labware(child_plate_d)
      end

      it 'makes the expected requests' do
        expect_custom_metadatum_collection_creation
        expect_plate_creation([child_plate_a, child_plate_b, child_plate_c, child_plate_d])
        expect_transfer_request_collection_creation

        expect(subject.save!).to be true

        expect(subject.redirection_target).to eq(plate)
      end
    end
  end

  context '384 well plate' do
    let(:transfer_requests_attributes) do
      # Hardcoding this to be explicit
      [
        { source_asset: '2-well-A1', target_asset: '3-well-A1', submission_id: '1' },
        { source_asset: '2-well-B1', target_asset: '4-well-A1', submission_id: '2' },
        { source_asset: '2-well-C1', target_asset: '3-well-B1', submission_id: '1' },
        { source_asset: '2-well-D1', target_asset: '4-well-B1', submission_id: '2' },
        { source_asset: '2-well-E1', target_asset: '3-well-C1', submission_id: '1' },
        { source_asset: '2-well-F1', target_asset: '4-well-C1', submission_id: '2' },
        { source_asset: '2-well-G1', target_asset: '3-well-D1', submission_id: '1' },
        { source_asset: '2-well-H1', target_asset: '4-well-D1', submission_id: '2' },
        { source_asset: '2-well-I1', target_asset: '3-well-E1', submission_id: '1' },
        { source_asset: '2-well-J1', target_asset: '4-well-E1', submission_id: '2' },
        { source_asset: '2-well-K1', target_asset: '3-well-F1', submission_id: '1' },
        { source_asset: '2-well-L1', target_asset: '4-well-F1', submission_id: '2' },
        { source_asset: '2-well-M1', target_asset: '3-well-G1', submission_id: '1' },
        { source_asset: '2-well-N1', target_asset: '4-well-G1', submission_id: '2' },
        { source_asset: '2-well-O1', target_asset: '3-well-H1', submission_id: '1' },
        { source_asset: '2-well-P1', target_asset: '4-well-H1', submission_id: '2' },
        { source_asset: '2-well-A2', target_asset: '5-well-A1', submission_id: '3' },
        { source_asset: '2-well-B2', target_asset: '6-well-A1', submission_id: '4' },
        { source_asset: '2-well-C2', target_asset: '5-well-B1', submission_id: '3' },
        { source_asset: '2-well-D2', target_asset: '6-well-B1', submission_id: '4' },
        { source_asset: '2-well-E2', target_asset: '5-well-C1', submission_id: '3' },
        { source_asset: '2-well-F2', target_asset: '6-well-C1', submission_id: '4' },
        { source_asset: '2-well-G2', target_asset: '5-well-D1', submission_id: '3' },
        { source_asset: '2-well-H2', target_asset: '6-well-D1', submission_id: '4' },
        { source_asset: '2-well-I2', target_asset: '5-well-E1', submission_id: '3' },
        { source_asset: '2-well-J2', target_asset: '6-well-E1', submission_id: '4' },
        { source_asset: '2-well-K2', target_asset: '5-well-F1', submission_id: '3' },
        { source_asset: '2-well-L2', target_asset: '6-well-F1', submission_id: '4' },
        { source_asset: '2-well-M2', target_asset: '5-well-G1', submission_id: '3' },
        { source_asset: '2-well-N2', target_asset: '6-well-G1', submission_id: '4' },
        { source_asset: '2-well-O2', target_asset: '5-well-H1', submission_id: '3' },
        { source_asset: '2-well-P2', target_asset: '6-well-H1', submission_id: '4' },
        { source_asset: '2-well-A3', target_asset: '3-well-A2', submission_id: '1' },
        { source_asset: '2-well-B3', target_asset: '4-well-A2', submission_id: '2' },
        { source_asset: '2-well-C3', target_asset: '3-well-B2', submission_id: '1' },
        { source_asset: '2-well-D3', target_asset: '4-well-B2', submission_id: '2' },
        { source_asset: '2-well-E3', target_asset: '3-well-C2', submission_id: '1' },
        { source_asset: '2-well-F3', target_asset: '4-well-C2', submission_id: '2' },
        { source_asset: '2-well-G3', target_asset: '3-well-D2', submission_id: '1' },
        { source_asset: '2-well-H3', target_asset: '4-well-D2', submission_id: '2' },
        { source_asset: '2-well-I3', target_asset: '3-well-E2', submission_id: '1' },
        { source_asset: '2-well-J3', target_asset: '4-well-E2', submission_id: '2' },
        { source_asset: '2-well-K3', target_asset: '3-well-F2', submission_id: '1' },
        { source_asset: '2-well-L3', target_asset: '4-well-F2', submission_id: '2' },
        { source_asset: '2-well-M3', target_asset: '3-well-G2', submission_id: '1' },
        { source_asset: '2-well-N3', target_asset: '4-well-G2', submission_id: '2' },
        { source_asset: '2-well-O3', target_asset: '3-well-H2', submission_id: '1' },
        { source_asset: '2-well-P3', target_asset: '4-well-H2', submission_id: '2' },
        { source_asset: '2-well-A4', target_asset: '5-well-A2', submission_id: '3' },
        { source_asset: '2-well-B4', target_asset: '6-well-A2', submission_id: '4' },
        { source_asset: '2-well-C4', target_asset: '5-well-B2', submission_id: '3' },
        { source_asset: '2-well-D4', target_asset: '6-well-B2', submission_id: '4' },
        { source_asset: '2-well-E4', target_asset: '5-well-C2', submission_id: '3' },
        { source_asset: '2-well-F4', target_asset: '6-well-C2', submission_id: '4' },
        { source_asset: '2-well-G4', target_asset: '5-well-D2', submission_id: '3' },
        { source_asset: '2-well-H4', target_asset: '6-well-D2', submission_id: '4' },
        { source_asset: '2-well-I4', target_asset: '5-well-E2', submission_id: '3' },
        { source_asset: '2-well-J4', target_asset: '6-well-E2', submission_id: '4' },
        { source_asset: '2-well-K4', target_asset: '5-well-F2', submission_id: '3' },
        { source_asset: '2-well-L4', target_asset: '6-well-F2', submission_id: '4' },
        { source_asset: '2-well-M4', target_asset: '5-well-G2', submission_id: '3' },
        { source_asset: '2-well-N4', target_asset: '6-well-G2', submission_id: '4' },
        { source_asset: '2-well-O4', target_asset: '5-well-H2', submission_id: '3' },
        { source_asset: '2-well-P4', target_asset: '6-well-H2', submission_id: '4' },
        { source_asset: '2-well-A5', target_asset: '3-well-A3', submission_id: '1' },
        { source_asset: '2-well-B5', target_asset: '4-well-A3', submission_id: '2' },
        { source_asset: '2-well-C5', target_asset: '3-well-B3', submission_id: '1' },
        { source_asset: '2-well-D5', target_asset: '4-well-B3', submission_id: '2' },
        { source_asset: '2-well-E5', target_asset: '3-well-C3', submission_id: '1' },
        { source_asset: '2-well-F5', target_asset: '4-well-C3', submission_id: '2' },
        { source_asset: '2-well-G5', target_asset: '3-well-D3', submission_id: '1' },
        { source_asset: '2-well-H5', target_asset: '4-well-D3', submission_id: '2' },
        { source_asset: '2-well-I5', target_asset: '3-well-E3', submission_id: '1' },
        { source_asset: '2-well-J5', target_asset: '4-well-E3', submission_id: '2' },
        { source_asset: '2-well-K5', target_asset: '3-well-F3', submission_id: '1' },
        { source_asset: '2-well-L5', target_asset: '4-well-F3', submission_id: '2' },
        { source_asset: '2-well-M5', target_asset: '3-well-G3', submission_id: '1' },
        { source_asset: '2-well-N5', target_asset: '4-well-G3', submission_id: '2' },
        { source_asset: '2-well-O5', target_asset: '3-well-H3', submission_id: '1' },
        { source_asset: '2-well-P5', target_asset: '4-well-H3', submission_id: '2' },
        { source_asset: '2-well-A6', target_asset: '5-well-A3', submission_id: '3' },
        { source_asset: '2-well-B6', target_asset: '6-well-A3', submission_id: '4' },
        { source_asset: '2-well-C6', target_asset: '5-well-B3', submission_id: '3' },
        { source_asset: '2-well-D6', target_asset: '6-well-B3', submission_id: '4' },
        { source_asset: '2-well-E6', target_asset: '5-well-C3', submission_id: '3' },
        { source_asset: '2-well-F6', target_asset: '6-well-C3', submission_id: '4' },
        { source_asset: '2-well-G6', target_asset: '5-well-D3', submission_id: '3' },
        { source_asset: '2-well-H6', target_asset: '6-well-D3', submission_id: '4' },
        { source_asset: '2-well-I6', target_asset: '5-well-E3', submission_id: '3' },
        { source_asset: '2-well-J6', target_asset: '6-well-E3', submission_id: '4' },
        { source_asset: '2-well-K6', target_asset: '5-well-F3', submission_id: '3' },
        { source_asset: '2-well-L6', target_asset: '6-well-F3', submission_id: '4' },
        { source_asset: '2-well-M6', target_asset: '5-well-G3', submission_id: '3' },
        { source_asset: '2-well-N6', target_asset: '6-well-G3', submission_id: '4' },
        { source_asset: '2-well-O6', target_asset: '5-well-H3', submission_id: '3' },
        { source_asset: '2-well-P6', target_asset: '6-well-H3', submission_id: '4' },
        { source_asset: '2-well-A7', target_asset: '3-well-A4', submission_id: '1' },
        { source_asset: '2-well-B7', target_asset: '4-well-A4', submission_id: '2' },
        { source_asset: '2-well-C7', target_asset: '3-well-B4', submission_id: '1' },
        { source_asset: '2-well-D7', target_asset: '4-well-B4', submission_id: '2' },
        { source_asset: '2-well-E7', target_asset: '3-well-C4', submission_id: '1' },
        { source_asset: '2-well-F7', target_asset: '4-well-C4', submission_id: '2' },
        { source_asset: '2-well-G7', target_asset: '3-well-D4', submission_id: '1' },
        { source_asset: '2-well-H7', target_asset: '4-well-D4', submission_id: '2' },
        { source_asset: '2-well-I7', target_asset: '3-well-E4', submission_id: '1' },
        { source_asset: '2-well-J7', target_asset: '4-well-E4', submission_id: '2' },
        { source_asset: '2-well-K7', target_asset: '3-well-F4', submission_id: '1' },
        { source_asset: '2-well-L7', target_asset: '4-well-F4', submission_id: '2' },
        { source_asset: '2-well-M7', target_asset: '3-well-G4', submission_id: '1' },
        { source_asset: '2-well-N7', target_asset: '4-well-G4', submission_id: '2' },
        { source_asset: '2-well-O7', target_asset: '3-well-H4', submission_id: '1' },
        { source_asset: '2-well-P7', target_asset: '4-well-H4', submission_id: '2' },
        { source_asset: '2-well-A8', target_asset: '5-well-A4', submission_id: '3' },
        { source_asset: '2-well-B8', target_asset: '6-well-A4', submission_id: '4' },
        { source_asset: '2-well-C8', target_asset: '5-well-B4', submission_id: '3' },
        { source_asset: '2-well-D8', target_asset: '6-well-B4', submission_id: '4' },
        { source_asset: '2-well-E8', target_asset: '5-well-C4', submission_id: '3' },
        { source_asset: '2-well-F8', target_asset: '6-well-C4', submission_id: '4' },
        { source_asset: '2-well-G8', target_asset: '5-well-D4', submission_id: '3' },
        { source_asset: '2-well-H8', target_asset: '6-well-D4', submission_id: '4' },
        { source_asset: '2-well-I8', target_asset: '5-well-E4', submission_id: '3' },
        { source_asset: '2-well-J8', target_asset: '6-well-E4', submission_id: '4' },
        { source_asset: '2-well-K8', target_asset: '5-well-F4', submission_id: '3' },
        { source_asset: '2-well-L8', target_asset: '6-well-F4', submission_id: '4' },
        { source_asset: '2-well-M8', target_asset: '5-well-G4', submission_id: '3' },
        { source_asset: '2-well-N8', target_asset: '6-well-G4', submission_id: '4' },
        { source_asset: '2-well-O8', target_asset: '5-well-H4', submission_id: '3' },
        { source_asset: '2-well-P8', target_asset: '6-well-H4', submission_id: '4' },
        { source_asset: '2-well-A9', target_asset: '3-well-A5', submission_id: '1' },
        { source_asset: '2-well-B9', target_asset: '4-well-A5', submission_id: '2' },
        { source_asset: '2-well-C9', target_asset: '3-well-B5', submission_id: '1' },
        { source_asset: '2-well-D9', target_asset: '4-well-B5', submission_id: '2' },
        { source_asset: '2-well-E9', target_asset: '3-well-C5', submission_id: '1' },
        { source_asset: '2-well-F9', target_asset: '4-well-C5', submission_id: '2' },
        { source_asset: '2-well-G9', target_asset: '3-well-D5', submission_id: '1' },
        { source_asset: '2-well-H9', target_asset: '4-well-D5', submission_id: '2' },
        { source_asset: '2-well-I9', target_asset: '3-well-E5', submission_id: '1' },
        { source_asset: '2-well-J9', target_asset: '4-well-E5', submission_id: '2' },
        { source_asset: '2-well-K9', target_asset: '3-well-F5', submission_id: '1' },
        { source_asset: '2-well-L9', target_asset: '4-well-F5', submission_id: '2' },
        { source_asset: '2-well-M9', target_asset: '3-well-G5', submission_id: '1' },
        { source_asset: '2-well-N9', target_asset: '4-well-G5', submission_id: '2' },
        { source_asset: '2-well-O9', target_asset: '3-well-H5', submission_id: '1' },
        { source_asset: '2-well-P9', target_asset: '4-well-H5', submission_id: '2' },
        { source_asset: '2-well-A10', target_asset: '5-well-A5', submission_id: '3' },
        { source_asset: '2-well-B10', target_asset: '6-well-A5', submission_id: '4' },
        { source_asset: '2-well-C10', target_asset: '5-well-B5', submission_id: '3' },
        { source_asset: '2-well-D10', target_asset: '6-well-B5', submission_id: '4' },
        { source_asset: '2-well-E10', target_asset: '5-well-C5', submission_id: '3' },
        { source_asset: '2-well-F10', target_asset: '6-well-C5', submission_id: '4' },
        { source_asset: '2-well-G10', target_asset: '5-well-D5', submission_id: '3' },
        { source_asset: '2-well-H10', target_asset: '6-well-D5', submission_id: '4' },
        { source_asset: '2-well-I10', target_asset: '5-well-E5', submission_id: '3' },
        { source_asset: '2-well-J10', target_asset: '6-well-E5', submission_id: '4' },
        { source_asset: '2-well-K10', target_asset: '5-well-F5', submission_id: '3' },
        { source_asset: '2-well-L10', target_asset: '6-well-F5', submission_id: '4' },
        { source_asset: '2-well-M10', target_asset: '5-well-G5', submission_id: '3' },
        { source_asset: '2-well-N10', target_asset: '6-well-G5', submission_id: '4' },
        { source_asset: '2-well-O10', target_asset: '5-well-H5', submission_id: '3' },
        { source_asset: '2-well-P10', target_asset: '6-well-H5', submission_id: '4' },
        { source_asset: '2-well-A11', target_asset: '3-well-A6', submission_id: '1' },
        { source_asset: '2-well-B11', target_asset: '4-well-A6', submission_id: '2' },
        { source_asset: '2-well-C11', target_asset: '3-well-B6', submission_id: '1' },
        { source_asset: '2-well-D11', target_asset: '4-well-B6', submission_id: '2' },
        { source_asset: '2-well-E11', target_asset: '3-well-C6', submission_id: '1' },
        { source_asset: '2-well-F11', target_asset: '4-well-C6', submission_id: '2' },
        { source_asset: '2-well-G11', target_asset: '3-well-D6', submission_id: '1' },
        { source_asset: '2-well-H11', target_asset: '4-well-D6', submission_id: '2' },
        { source_asset: '2-well-I11', target_asset: '3-well-E6', submission_id: '1' },
        { source_asset: '2-well-J11', target_asset: '4-well-E6', submission_id: '2' },
        { source_asset: '2-well-K11', target_asset: '3-well-F6', submission_id: '1' },
        { source_asset: '2-well-L11', target_asset: '4-well-F6', submission_id: '2' },
        { source_asset: '2-well-M11', target_asset: '3-well-G6', submission_id: '1' },
        { source_asset: '2-well-N11', target_asset: '4-well-G6', submission_id: '2' },
        { source_asset: '2-well-O11', target_asset: '3-well-H6', submission_id: '1' },
        { source_asset: '2-well-P11', target_asset: '4-well-H6', submission_id: '2' },
        { source_asset: '2-well-A12', target_asset: '5-well-A6', submission_id: '3' },
        { source_asset: '2-well-B12', target_asset: '6-well-A6', submission_id: '4' },
        { source_asset: '2-well-C12', target_asset: '5-well-B6', submission_id: '3' },
        { source_asset: '2-well-D12', target_asset: '6-well-B6', submission_id: '4' },
        { source_asset: '2-well-E12', target_asset: '5-well-C6', submission_id: '3' },
        { source_asset: '2-well-F12', target_asset: '6-well-C6', submission_id: '4' },
        { source_asset: '2-well-G12', target_asset: '5-well-D6', submission_id: '3' },
        { source_asset: '2-well-H12', target_asset: '6-well-D6', submission_id: '4' },
        { source_asset: '2-well-I12', target_asset: '5-well-E6', submission_id: '3' },
        { source_asset: '2-well-J12', target_asset: '6-well-E6', submission_id: '4' },
        { source_asset: '2-well-K12', target_asset: '5-well-F6', submission_id: '3' },
        { source_asset: '2-well-L12', target_asset: '6-well-F6', submission_id: '4' },
        { source_asset: '2-well-M12', target_asset: '5-well-G6', submission_id: '3' },
        { source_asset: '2-well-N12', target_asset: '6-well-G6', submission_id: '4' },
        { source_asset: '2-well-O12', target_asset: '5-well-H6', submission_id: '3' },
        { source_asset: '2-well-P12', target_asset: '6-well-H6', submission_id: '4' },
        { source_asset: '2-well-A13', target_asset: '3-well-A7', submission_id: '1' },
        { source_asset: '2-well-B13', target_asset: '4-well-A7', submission_id: '2' },
        { source_asset: '2-well-C13', target_asset: '3-well-B7', submission_id: '1' },
        { source_asset: '2-well-D13', target_asset: '4-well-B7', submission_id: '2' },
        { source_asset: '2-well-E13', target_asset: '3-well-C7', submission_id: '1' },
        { source_asset: '2-well-F13', target_asset: '4-well-C7', submission_id: '2' },
        { source_asset: '2-well-G13', target_asset: '3-well-D7', submission_id: '1' },
        { source_asset: '2-well-H13', target_asset: '4-well-D7', submission_id: '2' },
        { source_asset: '2-well-I13', target_asset: '3-well-E7', submission_id: '1' },
        { source_asset: '2-well-J13', target_asset: '4-well-E7', submission_id: '2' },
        { source_asset: '2-well-K13', target_asset: '3-well-F7', submission_id: '1' },
        { source_asset: '2-well-L13', target_asset: '4-well-F7', submission_id: '2' },
        { source_asset: '2-well-M13', target_asset: '3-well-G7', submission_id: '1' },
        { source_asset: '2-well-N13', target_asset: '4-well-G7', submission_id: '2' },
        { source_asset: '2-well-O13', target_asset: '3-well-H7', submission_id: '1' },
        { source_asset: '2-well-P13', target_asset: '4-well-H7', submission_id: '2' },
        { source_asset: '2-well-A14', target_asset: '5-well-A7', submission_id: '3' },
        { source_asset: '2-well-B14', target_asset: '6-well-A7', submission_id: '4' },
        { source_asset: '2-well-C14', target_asset: '5-well-B7', submission_id: '3' },
        { source_asset: '2-well-D14', target_asset: '6-well-B7', submission_id: '4' },
        { source_asset: '2-well-E14', target_asset: '5-well-C7', submission_id: '3' },
        { source_asset: '2-well-F14', target_asset: '6-well-C7', submission_id: '4' },
        { source_asset: '2-well-G14', target_asset: '5-well-D7', submission_id: '3' },
        { source_asset: '2-well-H14', target_asset: '6-well-D7', submission_id: '4' },
        { source_asset: '2-well-I14', target_asset: '5-well-E7', submission_id: '3' },
        { source_asset: '2-well-J14', target_asset: '6-well-E7', submission_id: '4' },
        { source_asset: '2-well-K14', target_asset: '5-well-F7', submission_id: '3' },
        { source_asset: '2-well-L14', target_asset: '6-well-F7', submission_id: '4' },
        { source_asset: '2-well-M14', target_asset: '5-well-G7', submission_id: '3' },
        { source_asset: '2-well-N14', target_asset: '6-well-G7', submission_id: '4' },
        { source_asset: '2-well-O14', target_asset: '5-well-H7', submission_id: '3' },
        { source_asset: '2-well-P14', target_asset: '6-well-H7', submission_id: '4' },
        { source_asset: '2-well-A15', target_asset: '3-well-A8', submission_id: '1' },
        { source_asset: '2-well-B15', target_asset: '4-well-A8', submission_id: '2' },
        { source_asset: '2-well-C15', target_asset: '3-well-B8', submission_id: '1' },
        { source_asset: '2-well-D15', target_asset: '4-well-B8', submission_id: '2' },
        { source_asset: '2-well-E15', target_asset: '3-well-C8', submission_id: '1' },
        { source_asset: '2-well-F15', target_asset: '4-well-C8', submission_id: '2' },
        { source_asset: '2-well-G15', target_asset: '3-well-D8', submission_id: '1' },
        { source_asset: '2-well-H15', target_asset: '4-well-D8', submission_id: '2' },
        { source_asset: '2-well-I15', target_asset: '3-well-E8', submission_id: '1' },
        { source_asset: '2-well-J15', target_asset: '4-well-E8', submission_id: '2' },
        { source_asset: '2-well-K15', target_asset: '3-well-F8', submission_id: '1' },
        { source_asset: '2-well-L15', target_asset: '4-well-F8', submission_id: '2' },
        { source_asset: '2-well-M15', target_asset: '3-well-G8', submission_id: '1' },
        { source_asset: '2-well-N15', target_asset: '4-well-G8', submission_id: '2' },
        { source_asset: '2-well-O15', target_asset: '3-well-H8', submission_id: '1' },
        { source_asset: '2-well-P15', target_asset: '4-well-H8', submission_id: '2' },
        { source_asset: '2-well-A16', target_asset: '5-well-A8', submission_id: '3' },
        { source_asset: '2-well-B16', target_asset: '6-well-A8', submission_id: '4' },
        { source_asset: '2-well-C16', target_asset: '5-well-B8', submission_id: '3' },
        { source_asset: '2-well-D16', target_asset: '6-well-B8', submission_id: '4' },
        { source_asset: '2-well-E16', target_asset: '5-well-C8', submission_id: '3' },
        { source_asset: '2-well-F16', target_asset: '6-well-C8', submission_id: '4' },
        { source_asset: '2-well-G16', target_asset: '5-well-D8', submission_id: '3' },
        { source_asset: '2-well-H16', target_asset: '6-well-D8', submission_id: '4' },
        { source_asset: '2-well-I16', target_asset: '5-well-E8', submission_id: '3' },
        { source_asset: '2-well-J16', target_asset: '6-well-E8', submission_id: '4' },
        { source_asset: '2-well-K16', target_asset: '5-well-F8', submission_id: '3' },
        { source_asset: '2-well-L16', target_asset: '6-well-F8', submission_id: '4' },
        { source_asset: '2-well-M16', target_asset: '5-well-G8', submission_id: '3' },
        { source_asset: '2-well-N16', target_asset: '6-well-G8', submission_id: '4' },
        { source_asset: '2-well-O16', target_asset: '5-well-H8', submission_id: '3' },
        { source_asset: '2-well-P16', target_asset: '6-well-H8', submission_id: '4' },
        { source_asset: '2-well-A17', target_asset: '3-well-A9', submission_id: '1' },
        { source_asset: '2-well-B17', target_asset: '4-well-A9', submission_id: '2' },
        { source_asset: '2-well-C17', target_asset: '3-well-B9', submission_id: '1' },
        { source_asset: '2-well-D17', target_asset: '4-well-B9', submission_id: '2' },
        { source_asset: '2-well-E17', target_asset: '3-well-C9', submission_id: '1' },
        { source_asset: '2-well-F17', target_asset: '4-well-C9', submission_id: '2' },
        { source_asset: '2-well-G17', target_asset: '3-well-D9', submission_id: '1' },
        { source_asset: '2-well-H17', target_asset: '4-well-D9', submission_id: '2' },
        { source_asset: '2-well-I17', target_asset: '3-well-E9', submission_id: '1' },
        { source_asset: '2-well-J17', target_asset: '4-well-E9', submission_id: '2' },
        { source_asset: '2-well-K17', target_asset: '3-well-F9', submission_id: '1' },
        { source_asset: '2-well-L17', target_asset: '4-well-F9', submission_id: '2' },
        { source_asset: '2-well-M17', target_asset: '3-well-G9', submission_id: '1' },
        { source_asset: '2-well-N17', target_asset: '4-well-G9', submission_id: '2' },
        { source_asset: '2-well-O17', target_asset: '3-well-H9', submission_id: '1' },
        { source_asset: '2-well-P17', target_asset: '4-well-H9', submission_id: '2' },
        { source_asset: '2-well-A18', target_asset: '5-well-A9', submission_id: '3' },
        { source_asset: '2-well-B18', target_asset: '6-well-A9', submission_id: '4' },
        { source_asset: '2-well-C18', target_asset: '5-well-B9', submission_id: '3' },
        { source_asset: '2-well-D18', target_asset: '6-well-B9', submission_id: '4' },
        { source_asset: '2-well-E18', target_asset: '5-well-C9', submission_id: '3' },
        { source_asset: '2-well-F18', target_asset: '6-well-C9', submission_id: '4' },
        { source_asset: '2-well-G18', target_asset: '5-well-D9', submission_id: '3' },
        { source_asset: '2-well-H18', target_asset: '6-well-D9', submission_id: '4' },
        { source_asset: '2-well-I18', target_asset: '5-well-E9', submission_id: '3' },
        { source_asset: '2-well-J18', target_asset: '6-well-E9', submission_id: '4' },
        { source_asset: '2-well-K18', target_asset: '5-well-F9', submission_id: '3' },
        { source_asset: '2-well-L18', target_asset: '6-well-F9', submission_id: '4' },
        { source_asset: '2-well-M18', target_asset: '5-well-G9', submission_id: '3' },
        { source_asset: '2-well-N18', target_asset: '6-well-G9', submission_id: '4' },
        { source_asset: '2-well-O18', target_asset: '5-well-H9', submission_id: '3' },
        { source_asset: '2-well-P18', target_asset: '6-well-H9', submission_id: '4' },
        { source_asset: '2-well-A19', target_asset: '3-well-A10', submission_id: '1' },
        { source_asset: '2-well-B19', target_asset: '4-well-A10', submission_id: '2' },
        { source_asset: '2-well-C19', target_asset: '3-well-B10', submission_id: '1' },
        { source_asset: '2-well-D19', target_asset: '4-well-B10', submission_id: '2' },
        { source_asset: '2-well-E19', target_asset: '3-well-C10', submission_id: '1' },
        { source_asset: '2-well-F19', target_asset: '4-well-C10', submission_id: '2' },
        { source_asset: '2-well-G19', target_asset: '3-well-D10', submission_id: '1' },
        { source_asset: '2-well-H19', target_asset: '4-well-D10', submission_id: '2' },
        { source_asset: '2-well-I19', target_asset: '3-well-E10', submission_id: '1' },
        { source_asset: '2-well-J19', target_asset: '4-well-E10', submission_id: '2' },
        { source_asset: '2-well-K19', target_asset: '3-well-F10', submission_id: '1' },
        { source_asset: '2-well-L19', target_asset: '4-well-F10', submission_id: '2' },
        { source_asset: '2-well-M19', target_asset: '3-well-G10', submission_id: '1' },
        { source_asset: '2-well-N19', target_asset: '4-well-G10', submission_id: '2' },
        { source_asset: '2-well-O19', target_asset: '3-well-H10', submission_id: '1' },
        { source_asset: '2-well-P19', target_asset: '4-well-H10', submission_id: '2' },
        { source_asset: '2-well-A20', target_asset: '5-well-A10', submission_id: '3' },
        { source_asset: '2-well-B20', target_asset: '6-well-A10', submission_id: '4' },
        { source_asset: '2-well-C20', target_asset: '5-well-B10', submission_id: '3' },
        { source_asset: '2-well-D20', target_asset: '6-well-B10', submission_id: '4' },
        { source_asset: '2-well-E20', target_asset: '5-well-C10', submission_id: '3' },
        { source_asset: '2-well-F20', target_asset: '6-well-C10', submission_id: '4' },
        { source_asset: '2-well-G20', target_asset: '5-well-D10', submission_id: '3' },
        { source_asset: '2-well-H20', target_asset: '6-well-D10', submission_id: '4' },
        { source_asset: '2-well-I20', target_asset: '5-well-E10', submission_id: '3' },
        { source_asset: '2-well-J20', target_asset: '6-well-E10', submission_id: '4' },
        { source_asset: '2-well-K20', target_asset: '5-well-F10', submission_id: '3' },
        { source_asset: '2-well-L20', target_asset: '6-well-F10', submission_id: '4' },
        { source_asset: '2-well-M20', target_asset: '5-well-G10', submission_id: '3' },
        { source_asset: '2-well-N20', target_asset: '6-well-G10', submission_id: '4' },
        { source_asset: '2-well-O20', target_asset: '5-well-H10', submission_id: '3' },
        { source_asset: '2-well-P20', target_asset: '6-well-H10', submission_id: '4' },
        { source_asset: '2-well-A21', target_asset: '3-well-A11', submission_id: '1' },
        { source_asset: '2-well-B21', target_asset: '4-well-A11', submission_id: '2' },
        { source_asset: '2-well-C21', target_asset: '3-well-B11', submission_id: '1' },
        { source_asset: '2-well-D21', target_asset: '4-well-B11', submission_id: '2' },
        { source_asset: '2-well-E21', target_asset: '3-well-C11', submission_id: '1' },
        { source_asset: '2-well-F21', target_asset: '4-well-C11', submission_id: '2' },
        { source_asset: '2-well-G21', target_asset: '3-well-D11', submission_id: '1' },
        { source_asset: '2-well-H21', target_asset: '4-well-D11', submission_id: '2' },
        { source_asset: '2-well-I21', target_asset: '3-well-E11', submission_id: '1' },
        { source_asset: '2-well-J21', target_asset: '4-well-E11', submission_id: '2' },
        { source_asset: '2-well-K21', target_asset: '3-well-F11', submission_id: '1' },
        { source_asset: '2-well-L21', target_asset: '4-well-F11', submission_id: '2' },
        { source_asset: '2-well-M21', target_asset: '3-well-G11', submission_id: '1' },
        { source_asset: '2-well-N21', target_asset: '4-well-G11', submission_id: '2' },
        { source_asset: '2-well-O21', target_asset: '3-well-H11', submission_id: '1' },
        { source_asset: '2-well-P21', target_asset: '4-well-H11', submission_id: '2' },
        { source_asset: '2-well-A22', target_asset: '5-well-A11', submission_id: '3' },
        { source_asset: '2-well-B22', target_asset: '6-well-A11', submission_id: '4' },
        { source_asset: '2-well-C22', target_asset: '5-well-B11', submission_id: '3' },
        { source_asset: '2-well-D22', target_asset: '6-well-B11', submission_id: '4' },
        { source_asset: '2-well-E22', target_asset: '5-well-C11', submission_id: '3' },
        { source_asset: '2-well-F22', target_asset: '6-well-C11', submission_id: '4' },
        { source_asset: '2-well-G22', target_asset: '5-well-D11', submission_id: '3' },
        { source_asset: '2-well-H22', target_asset: '6-well-D11', submission_id: '4' },
        { source_asset: '2-well-I22', target_asset: '5-well-E11', submission_id: '3' },
        { source_asset: '2-well-J22', target_asset: '6-well-E11', submission_id: '4' },
        { source_asset: '2-well-K22', target_asset: '5-well-F11', submission_id: '3' },
        { source_asset: '2-well-L22', target_asset: '6-well-F11', submission_id: '4' },
        { source_asset: '2-well-M22', target_asset: '5-well-G11', submission_id: '3' },
        { source_asset: '2-well-N22', target_asset: '6-well-G11', submission_id: '4' },
        { source_asset: '2-well-O22', target_asset: '5-well-H11', submission_id: '3' },
        { source_asset: '2-well-P22', target_asset: '6-well-H11', submission_id: '4' },
        { source_asset: '2-well-A23', target_asset: '3-well-A12', submission_id: '1' },
        { source_asset: '2-well-B23', target_asset: '4-well-A12', submission_id: '2' },
        { source_asset: '2-well-C23', target_asset: '3-well-B12', submission_id: '1' },
        { source_asset: '2-well-D23', target_asset: '4-well-B12', submission_id: '2' },
        { source_asset: '2-well-E23', target_asset: '3-well-C12', submission_id: '1' },
        { source_asset: '2-well-F23', target_asset: '4-well-C12', submission_id: '2' },
        { source_asset: '2-well-G23', target_asset: '3-well-D12', submission_id: '1' },
        { source_asset: '2-well-H23', target_asset: '4-well-D12', submission_id: '2' },
        { source_asset: '2-well-I23', target_asset: '3-well-E12', submission_id: '1' },
        { source_asset: '2-well-J23', target_asset: '4-well-E12', submission_id: '2' },
        { source_asset: '2-well-K23', target_asset: '3-well-F12', submission_id: '1' },
        { source_asset: '2-well-L23', target_asset: '4-well-F12', submission_id: '2' },
        { source_asset: '2-well-M23', target_asset: '3-well-G12', submission_id: '1' },
        { source_asset: '2-well-N23', target_asset: '4-well-G12', submission_id: '2' },
        { source_asset: '2-well-O23', target_asset: '3-well-H12', submission_id: '1' },
        { source_asset: '2-well-P23', target_asset: '4-well-H12', submission_id: '2' },
        { source_asset: '2-well-A24', target_asset: '5-well-A12', submission_id: '3' },
        { source_asset: '2-well-B24', target_asset: '6-well-A12', submission_id: '4' },
        { source_asset: '2-well-C24', target_asset: '5-well-B12', submission_id: '3' },
        { source_asset: '2-well-D24', target_asset: '6-well-B12', submission_id: '4' },
        { source_asset: '2-well-E24', target_asset: '5-well-C12', submission_id: '3' },
        { source_asset: '2-well-F24', target_asset: '6-well-C12', submission_id: '4' },
        { source_asset: '2-well-G24', target_asset: '5-well-D12', submission_id: '3' },
        { source_asset: '2-well-H24', target_asset: '6-well-D12', submission_id: '4' },
        { source_asset: '2-well-I24', target_asset: '5-well-E12', submission_id: '3' },
        { source_asset: '2-well-J24', target_asset: '6-well-E12', submission_id: '4' },
        { source_asset: '2-well-K24', target_asset: '5-well-F12', submission_id: '3' },
        { source_asset: '2-well-L24', target_asset: '6-well-F12', submission_id: '4' },
        { source_asset: '2-well-M24', target_asset: '5-well-G12', submission_id: '3' },
        { source_asset: '2-well-N24', target_asset: '6-well-G12', submission_id: '4' },
        { source_asset: '2-well-O24', target_asset: '5-well-H12', submission_id: '3' },
        { source_asset: '2-well-P24', target_asset: '6-well-H12', submission_id: '4' }
      ]
    end

    it_behaves_like 'a quad-split plate creator'
  end
end
