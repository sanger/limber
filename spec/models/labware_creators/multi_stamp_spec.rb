# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Wells from a number of 96 well parent plates are transferred into a 96 well child plate.
RSpec.describe LabwareCreators::MultiStamp do
  it_behaves_like 'it only allows creation from plates'

  let(:parent1_uuid) { 'parent1-plate-uuid' }
  let(:parent2_uuid) { 'parent2-plate-uuid' }

  let(:requests_parent1) { Array.new(24) { |i| create :library_request, state: 'started', uuid: "request-p1-#{i}" } }
  let(:requests_parent2) { Array.new(24) { |i| create :library_request, state: 'started', uuid: "request-p2-#{i}" } }

  let(:stock_plate1) { create :stock_plate_for_plate, barcode_number: '1' }
  let(:stock_plate2) { create :stock_plate_for_plate, barcode_number: '2' }

  let(:parent1) do
    create(
      :plate,
      barcode_number: '3',
      uuid: parent1_uuid,
      size: 96,
      outer_requests: requests_parent1,
      well_count: 24,
      stock_plate: stock_plate1
    )
  end
  let(:parent2) do
    create(
      :plate,
      barcode_number: '4',
      uuid: parent2_uuid,
      size: 96,
      outer_requests: requests_parent2,
      well_count: 24,
      stock_plate: stock_plate2
    )
  end
  let(:child_plate) { create :plate, barcode_number: '5', size: 96 }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  before do
    create :purpose_config, name: child_purpose_name, uuid: child_purpose_uuid

    stub_plate(parent1, stub_search: false)
    stub_plate(parent2, stub_search: false)
    stub_plate(child_plate, stub_search: false, custom_query: [:plate_with_wells, child_plate.uuid])
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
    subject { described_class.new(form_attributes.merge(user_uuid:)) }

    let(:form_attributes) do
      {
        parent_uuid: parent1_uuid,
        purpose_uuid: child_purpose_uuid,
        transfers: [
          # from parent 1
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-A1',
            outer_request: 'request-p1-1',
            new_target: {
              location: 'A1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-B1',
            outer_request: 'request-p1-2',
            new_target: {
              location: 'B1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-C1',
            outer_request: 'request-p1-3',
            new_target: {
              location: 'C1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-D1',
            outer_request: 'request-p1-4',
            new_target: {
              location: 'D1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-E1',
            outer_request: 'request-p1-5',
            new_target: {
              location: 'E1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-F1',
            outer_request: 'request-p1-6',
            new_target: {
              location: 'F1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-G1',
            outer_request: 'request-p1-7',
            new_target: {
              location: 'G1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-H1',
            outer_request: 'request-p1-8',
            new_target: {
              location: 'H1'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-A2',
            outer_request: 'request-p1-9',
            new_target: {
              location: 'A2'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-B2',
            outer_request: 'request-p1-10',
            new_target: {
              location: 'B2'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-C2',
            outer_request: 'request-p1-11',
            new_target: {
              location: 'C2'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-D2',
            outer_request: 'request-p1-12',
            new_target: {
              location: 'D2'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-E2',
            outer_request: 'request-p1-13',
            new_target: {
              location: 'E2'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-F2',
            outer_request: 'request-p1-14',
            new_target: {
              location: 'F2'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-G2',
            outer_request: 'request-p1-15',
            new_target: {
              location: 'G2'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-H2',
            outer_request: 'request-p1-16',
            new_target: {
              location: 'H2'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-A3',
            outer_request: 'request-p1-17',
            new_target: {
              location: 'A3'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-B3',
            outer_request: 'request-p1-18',
            new_target: {
              location: 'B3'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-C3',
            outer_request: 'request-p1-19',
            new_target: {
              location: 'C3'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-D3',
            outer_request: 'request-p1-20',
            new_target: {
              location: 'D3'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-E3',
            outer_request: 'request-p1-21',
            new_target: {
              location: 'E3'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-F3',
            outer_request: 'request-p1-22',
            new_target: {
              location: 'F3'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-G3',
            outer_request: 'request-p1-23',
            new_target: {
              location: 'G3'
            }
          },
          {
            source_plate: parent1_uuid,
            source_asset: '3-well-H3',
            outer_request: 'request-p1-24',
            new_target: {
              location: 'H3'
            }
          },
          # from parent 2
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-A1',
            outer_request: 'request-p2-1',
            new_target: {
              location: 'A4'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-B1',
            outer_request: 'request-p2-2',
            new_target: {
              location: 'B4'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-C1',
            outer_request: 'request-p2-3',
            new_target: {
              location: 'C4'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-D1',
            outer_request: 'request-p2-4',
            new_target: {
              location: 'D4'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-E1',
            outer_request: 'request-p2-5',
            new_target: {
              location: 'E4'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-F1',
            outer_request: 'request-p2-6',
            new_target: {
              location: 'F4'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-G1',
            outer_request: 'request-p2-7',
            new_target: {
              location: 'G4'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-H1',
            outer_request: 'request-p2-8',
            new_target: {
              location: 'H4'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-A2',
            outer_request: 'request-p2-9',
            new_target: {
              location: 'A5'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-B2',
            outer_request: 'request-p2-10',
            new_target: {
              location: 'B5'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-C2',
            outer_request: 'request-p2-11',
            new_target: {
              location: 'C5'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-D2',
            outer_request: 'request-p2-12',
            new_target: {
              location: 'D5'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-E2',
            outer_request: 'request-p2-13',
            new_target: {
              location: 'E5'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-F2',
            outer_request: 'request-p2-14',
            new_target: {
              location: 'F5'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-G2',
            outer_request: 'request-p2-15',
            new_target: {
              location: 'G5'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-H2',
            outer_request: 'request-p2-16',
            new_target: {
              location: 'H5'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-A3',
            outer_request: 'request-p2-17',
            new_target: {
              location: 'A6'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-B3',
            outer_request: 'request-p2-18',
            new_target: {
              location: 'B6'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-C3',
            outer_request: 'request-p2-19',
            new_target: {
              location: 'C6'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-D3',
            outer_request: 'request-p2-20',
            new_target: {
              location: 'D6'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-E3',
            outer_request: 'request-p2-21',
            new_target: {
              location: 'E6'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-F3',
            outer_request: 'request-p2-22',
            new_target: {
              location: 'F6'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-G3',
            outer_request: 'request-p2-23',
            new_target: {
              location: 'G6'
            }
          },
          {
            source_plate: parent2_uuid,
            source_asset: '4-well-H3',
            outer_request: 'request-p2-24',
            new_target: {
              location: 'H6'
            }
          }
        ]
      }
    end

    let(:transfer_requests_attributes) do
      [
        { source_asset: '3-well-A1', outer_request: 'request-p1-1', target_asset: '5-well-A1' },
        { source_asset: '3-well-B1', outer_request: 'request-p1-2', target_asset: '5-well-B1' },
        { source_asset: '3-well-C1', outer_request: 'request-p1-3', target_asset: '5-well-C1' },
        { source_asset: '3-well-D1', outer_request: 'request-p1-4', target_asset: '5-well-D1' },
        { source_asset: '3-well-E1', outer_request: 'request-p1-5', target_asset: '5-well-E1' },
        { source_asset: '3-well-F1', outer_request: 'request-p1-6', target_asset: '5-well-F1' },
        { source_asset: '3-well-G1', outer_request: 'request-p1-7', target_asset: '5-well-G1' },
        { source_asset: '3-well-H1', outer_request: 'request-p1-8', target_asset: '5-well-H1' },
        { source_asset: '3-well-A2', outer_request: 'request-p1-9', target_asset: '5-well-A2' },
        { source_asset: '3-well-B2', outer_request: 'request-p1-10', target_asset: '5-well-B2' },
        { source_asset: '3-well-C2', outer_request: 'request-p1-11', target_asset: '5-well-C2' },
        { source_asset: '3-well-D2', outer_request: 'request-p1-12', target_asset: '5-well-D2' },
        { source_asset: '3-well-E2', outer_request: 'request-p1-13', target_asset: '5-well-E2' },
        { source_asset: '3-well-F2', outer_request: 'request-p1-14', target_asset: '5-well-F2' },
        { source_asset: '3-well-G2', outer_request: 'request-p1-15', target_asset: '5-well-G2' },
        { source_asset: '3-well-H2', outer_request: 'request-p1-16', target_asset: '5-well-H2' },
        { source_asset: '3-well-A3', outer_request: 'request-p1-17', target_asset: '5-well-A3' },
        { source_asset: '3-well-B3', outer_request: 'request-p1-18', target_asset: '5-well-B3' },
        { source_asset: '3-well-C3', outer_request: 'request-p1-19', target_asset: '5-well-C3' },
        { source_asset: '3-well-D3', outer_request: 'request-p1-20', target_asset: '5-well-D3' },
        { source_asset: '3-well-E3', outer_request: 'request-p1-21', target_asset: '5-well-E3' },
        { source_asset: '3-well-F3', outer_request: 'request-p1-22', target_asset: '5-well-F3' },
        { source_asset: '3-well-G3', outer_request: 'request-p1-23', target_asset: '5-well-G3' },
        { source_asset: '3-well-H3', outer_request: 'request-p1-24', target_asset: '5-well-H3' },
        { source_asset: '4-well-A1', outer_request: 'request-p2-1', target_asset: '5-well-A4' },
        { source_asset: '4-well-B1', outer_request: 'request-p2-2', target_asset: '5-well-B4' },
        { source_asset: '4-well-C1', outer_request: 'request-p2-3', target_asset: '5-well-C4' },
        { source_asset: '4-well-D1', outer_request: 'request-p2-4', target_asset: '5-well-D4' },
        { source_asset: '4-well-E1', outer_request: 'request-p2-5', target_asset: '5-well-E4' },
        { source_asset: '4-well-F1', outer_request: 'request-p2-6', target_asset: '5-well-F4' },
        { source_asset: '4-well-G1', outer_request: 'request-p2-7', target_asset: '5-well-G4' },
        { source_asset: '4-well-H1', outer_request: 'request-p2-8', target_asset: '5-well-H4' },
        { source_asset: '4-well-A2', outer_request: 'request-p2-9', target_asset: '5-well-A5' },
        { source_asset: '4-well-B2', outer_request: 'request-p2-10', target_asset: '5-well-B5' },
        { source_asset: '4-well-C2', outer_request: 'request-p2-11', target_asset: '5-well-C5' },
        { source_asset: '4-well-D2', outer_request: 'request-p2-12', target_asset: '5-well-D5' },
        { source_asset: '4-well-E2', outer_request: 'request-p2-13', target_asset: '5-well-E5' },
        { source_asset: '4-well-F2', outer_request: 'request-p2-14', target_asset: '5-well-F5' },
        { source_asset: '4-well-G2', outer_request: 'request-p2-15', target_asset: '5-well-G5' },
        { source_asset: '4-well-H2', outer_request: 'request-p2-16', target_asset: '5-well-H5' },
        { source_asset: '4-well-A3', outer_request: 'request-p2-17', target_asset: '5-well-A6' },
        { source_asset: '4-well-B3', outer_request: 'request-p2-18', target_asset: '5-well-B6' },
        { source_asset: '4-well-C3', outer_request: 'request-p2-19', target_asset: '5-well-C6' },
        { source_asset: '4-well-D3', outer_request: 'request-p2-20', target_asset: '5-well-D6' },
        { source_asset: '4-well-E3', outer_request: 'request-p2-21', target_asset: '5-well-E6' },
        { source_asset: '4-well-F3', outer_request: 'request-p2-22', target_asset: '5-well-F6' },
        { source_asset: '4-well-G3', outer_request: 'request-p2-23', target_asset: '5-well-G6' },
        { source_asset: '4-well-H3', outer_request: 'request-p2-24', target_asset: '5-well-H6' }
      ]
    end

    let(:pooled_plates_attributes) do
      [{ child_purpose_uuid: child_purpose_uuid, parent_uuids: [parent1_uuid, parent2_uuid], user_uuid: user_uuid }]
    end

    describe '#save!' do
      it 'creates a plate!' do
        expect_pooled_plate_creation
        expect_transfer_request_collection_creation

        subject.save!

        expect(subject.child.uuid).to eq(child_plate.uuid)
        expect(subject).to be_valid
        expect(subject.errors.messages).to be_empty
      end
    end
  end
end
