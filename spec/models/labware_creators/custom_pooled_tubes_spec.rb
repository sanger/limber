# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Parent in a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
RSpec.describe LabwareCreators::CustomPooledTubes, with: :uploader do
  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from charged and passed plates'

  it 'has page' do
    expect(described_class.page).to eq 'custom_pooled_tubes'
  end

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:parent_uuid) { SecureRandom.uuid }
  let(:pool_size) { 16 }
  let(:stock_plate) { create(:v2_stock_plate_for_plate, barcode_number: 5) }
  let(:parent_plate) do
    create(
      :v2_plate,
      uuid: parent_uuid,
      pool_sizes: [pool_size],
      well_states: ['passed'] * pool_size,
      well_uuid_result: 'example-well-uuid-%s',
      stock_plate: stock_plate
    )
  end
  let(:form_attributes) { { purpose_uuid:, parent_uuid: } }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a described_class
    end
  end

  describe '#save' do
    let(:file_contents) do
      contents = file.read
      file.rewind
      contents
    end

    let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid:, file: } }

    let(:qc_files_attributes) do
      [
        {
          contents: file_contents,
          filename: 'robot_pooling_file.csv',
          relationships: {
            labware: {
              data: {
                id: parent_plate.id,
                type: 'labware'
              }
            }
          }
        }
      ]
    end

    let(:specific_tubes_attributes) do
      child_tubes = [
        create(:v2_tube, name: 'DN5 A1:B2', uuid: 'tube-0'),
        create(:v2_tube, name: 'DN5 C1:G2', uuid: 'tube-1')
      ]

      [
        {
          uuid: purpose_uuid,
          parent_uuids: [parent_uuid],
          child_tubes: child_tubes,
          tube_attributes: child_tubes.map { |tube| { name: tube.name } }
        }
      ]
    end

    let(:transfer_requests_attributes) do
      [
        { source_asset: 'example-well-uuid-A1', target_asset: 'tube-0' },
        { source_asset: 'example-well-uuid-B1', target_asset: 'tube-0' },
        { source_asset: 'example-well-uuid-D1', target_asset: 'tube-0' },
        { source_asset: 'example-well-uuid-E1', target_asset: 'tube-0' },
        { source_asset: 'example-well-uuid-F1', target_asset: 'tube-0' },
        { source_asset: 'example-well-uuid-G1', target_asset: 'tube-0' },
        { source_asset: 'example-well-uuid-H1', target_asset: 'tube-0' },
        { source_asset: 'example-well-uuid-A2', target_asset: 'tube-0' },
        { source_asset: 'example-well-uuid-B2', target_asset: 'tube-0' },
        { source_asset: 'example-well-uuid-C1', target_asset: 'tube-1' },
        { source_asset: 'example-well-uuid-C2', target_asset: 'tube-1' },
        { source_asset: 'example-well-uuid-D2', target_asset: 'tube-1' },
        { source_asset: 'example-well-uuid-E2', target_asset: 'tube-1' },
        { source_asset: 'example-well-uuid-F2', target_asset: 'tube-1' },
        { source_asset: 'example-well-uuid-G2', target_asset: 'tube-1' }
      ]
    end

    before { stub_v2_plate(parent_plate, stub_search: false) }

    context 'with a valid file' do
      let(:file) do
        fixture_file_upload('spec/fixtures/files/custom_pooled_tubes/pooling_file.csv', 'sequencescape/qc_file')
      end

      it 'pools according to the file' do
        expect_qc_file_creation
        expect_specific_tube_creation
        expect_transfer_request_collection_creation

        expect(subject.save).to be true
      end
    end

    context 'with an invalid file' do
      let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

      it 'is false' do
        expect(subject.save).to be false
      end
    end

    context 'with empty wells included' do
      let(:file) do
        fixture_file_upload('spec/fixtures/files/custom_pooled_tubes/pooling_file.csv', 'sequencescape/qc_file')
      end

      let(:pool_size) { 8 }

      it 'is false' do
        expect(subject.save).to be false
      end
    end
  end
end
