# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Up to four 96 well plates are transferred onto a single 384 well plate.
# Filtering can be done via primer panel.
RSpec.describe LabwareCreators::QuadrantStampPrimerPanel do
  it_behaves_like 'it only allows creation from plates'

  let(:parent1_uuid) { 'example-plate-uuid' }
  let(:parent2_uuid) { 'example-plate2-uuid' }
  let(:requests) { Array.new(96) { |i| create :gbs_library_request, state: 'started', uuid: "request-#{i}" } }
  let(:requests2) { Array.new(96) { |i| create :gbs_library_request, state: 'started', uuid: "request-#{i}" } }
  let(:stock_plate1) { create :v2_stock_plate_for_plate, barcode_number: '1' }
  let(:stock_plate2) { create :v2_stock_plate_for_plate, barcode_number: '2' }
  let(:parent1) do
    create(
      :v2_plate_with_primer_panels,
      barcode_number: '3',
      uuid: parent1_uuid,
      size: 96,
      outer_requests: requests,
      well_count: 10,
      stock_plate: stock_plate1
    )
  end
  let(:parent2) do
    create(
      :v2_plate_with_primer_panels,
      barcode_number: '4',
      uuid: parent2_uuid,
      size: 96,
      outer_requests: requests2,
      well_count: 10,
      stock_plate: stock_plate2
    )
  end
  let(:child_plate) { create :v2_plate, barcode_number: '5', size: 384 }
  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user) { create :user }
  let(:user_uuid) { user.uuid }

  before do
    create :purpose_config, name: child_purpose_name
    stub_v2_user(user)
    stub_v2_plate(parent1, stub_search: false)
    stub_v2_plate(parent2, stub_search: false)
    stub_v2_plate(child_plate, stub_search: false, custom_query: [:plate_with_wells, child_plate.uuid])
  end

  context 'on new' do
    subject { described_class.new(form_attributes) }

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent1_uuid } }

    it 'can be created' do
      expect(subject).to be_a described_class
    end

    it 'renders the "multi_stamp" page' do
      expect(subject.page).to eq('multi_stamp')
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_purpose_uuid)
    end
  end

  context 'on create' do
    subject { described_class.new(form_attributes.merge(user_uuid: user.uuid)) }

    let(:form_attributes) do
      {
        parent_uuid: parent1_uuid,
        purpose_uuid: child_purpose_uuid,
        transfers: [
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-A1',
            outer_request: 'request-0',
            new_target: {
              location: 'A1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-B1',
            outer_request: 'request-1',
            new_target: {
              location: 'C1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-C1',
            outer_request: 'request-2',
            new_target: {
              location: 'E1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-D1',
            outer_request: 'request-3',
            new_target: {
              location: 'G1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-E1',
            outer_request: 'request-4',
            new_target: {
              location: 'I1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-F1',
            outer_request: 'request-5',
            new_target: {
              location: 'K1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-G1',
            outer_request: 'request-6',
            new_target: {
              location: 'M1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-H1',
            outer_request: 'request-7',
            new_target: {
              location: 'O1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-A2',
            outer_request: 'request-8',
            new_target: {
              location: 'A3'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-B2',
            outer_request: 'request-9',
            new_target: {
              location: 'C3'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-A1',
            outer_request: 'request-0',
            new_target: {
              location: 'B1'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-B1',
            outer_request: 'request-1',
            new_target: {
              location: 'D1'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-C1',
            outer_request: 'request-2',
            new_target: {
              location: 'F1'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-D1',
            outer_request: 'request-3',
            new_target: {
              location: 'H1'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-E1',
            outer_request: 'request-4',
            new_target: {
              location: 'J1'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-F1',
            outer_request: 'request-5',
            new_target: {
              location: 'L1'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-G1',
            outer_request: 'request-6',
            new_target: {
              location: 'N1'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-H1',
            outer_request: 'request-7',
            new_target: {
              location: 'P1'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-A2',
            outer_request: 'request-8',
            new_target: {
              location: 'B3'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-B2',
            outer_request: 'request-9',
            new_target: {
              location: 'D3'
            }
          }
        ]
      }
    end

    let(:custom_metadatum_collections_attributes) do
      [
        {
          asset_id: child_plate.id,
          metadata: {
            stock_barcode_q0: stock_plate1.barcode.human,
            stock_barcode_q1: stock_plate2.barcode.human
          },
          user_id: user.id
        }
      ]
    end

    let(:transfer_requests_attributes) do
      [
        { source_asset: '3-well-A1', outer_request: 'request-0', target_asset: '5-well-A1' },
        { source_asset: '3-well-B1', outer_request: 'request-1', target_asset: '5-well-C1' },
        { source_asset: '3-well-C1', outer_request: 'request-2', target_asset: '5-well-E1' },
        { source_asset: '3-well-D1', outer_request: 'request-3', target_asset: '5-well-G1' },
        { source_asset: '3-well-E1', outer_request: 'request-4', target_asset: '5-well-I1' },
        { source_asset: '3-well-F1', outer_request: 'request-5', target_asset: '5-well-K1' },
        { source_asset: '3-well-G1', outer_request: 'request-6', target_asset: '5-well-M1' },
        { source_asset: '3-well-H1', outer_request: 'request-7', target_asset: '5-well-O1' },
        { source_asset: '3-well-A2', outer_request: 'request-8', target_asset: '5-well-A3' },
        { source_asset: '3-well-B2', outer_request: 'request-9', target_asset: '5-well-C3' },
        { source_asset: '4-well-A1', outer_request: 'request-0', target_asset: '5-well-B1' },
        { source_asset: '4-well-B1', outer_request: 'request-1', target_asset: '5-well-D1' },
        { source_asset: '4-well-C1', outer_request: 'request-2', target_asset: '5-well-F1' },
        { source_asset: '4-well-D1', outer_request: 'request-3', target_asset: '5-well-H1' },
        { source_asset: '4-well-E1', outer_request: 'request-4', target_asset: '5-well-J1' },
        { source_asset: '4-well-F1', outer_request: 'request-5', target_asset: '5-well-L1' },
        { source_asset: '4-well-G1', outer_request: 'request-6', target_asset: '5-well-N1' },
        { source_asset: '4-well-H1', outer_request: 'request-7', target_asset: '5-well-P1' },
        { source_asset: '4-well-A2', outer_request: 'request-8', target_asset: '5-well-B3' },
        { source_asset: '4-well-B2', outer_request: 'request-9', target_asset: '5-well-D3' }
      ]
    end

    let(:pooled_plates_attributes) do
      [{ child_purpose_uuid: child_purpose_uuid, parent_uuids: [parent1_uuid, parent2_uuid], user_uuid: user.uuid }]
    end

    describe '#save!' do
      it 'creates a plate!' do
        expect_custom_metadatum_collection_creation
        expect_pooled_plate_creation
        expect_transfer_request_collection_creation

        subject.save!
      end
    end
  end
end
