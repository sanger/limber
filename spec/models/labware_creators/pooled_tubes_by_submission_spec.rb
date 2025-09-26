# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Parent is a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
RSpec.describe LabwareCreators::PooledTubesBySubmission do
  include FeatureHelpers

  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from charged and passed plates with defined downstream pools'

  let(:user_uuid) { SecureRandom.uuid }

  let(:purpose_uuid) { SecureRandom.uuid }

  let(:stock_plate) { create(:stock_plate_for_plate, barcode_number: 5) }
  let(:parent_uuid) { SecureRandom.uuid }
  let(:parent_plate) do
    create(
      :plate,
      :has_pooling_metadata,
      uuid: parent_uuid,
      pool_sizes: [3, 6],
      well_states: ['passed'] * 9,
      well_uuid_result: 'example-well-uuid-%s',
      for_multiplexing: true,
      stock_plate: stock_plate
    )
  end

  let(:source_plate) { create :plate, uuid: parent_uuid }

  let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid: } }

  before { stub_plate(source_plate, stub_search: false) }

  describe '#save!' do
    let(:child_1_name) { 'DN5 A1:C1' }
    let(:child_2_name) { 'DN5 D1:A2' }

    let(:tube_attributes) { [{ name: child_1_name }, { name: child_2_name }] }

    let(:child_tubes) do
      # Prepare child tubes and stub their lookups.
      child_tubes =
        tube_attributes.each_with_index.map do |attrs, index|
          create(:tube, name: attrs[:name], uuid: "tube-#{index}")
        end
      child_tubes.each { |child_tube| stub_labware(child_tube) }

      child_tubes
    end

    let(:specific_tubes_attributes) do
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
        { source_asset: 'example-well-uuid-A1', target_asset: 'tube-0', submission: 'pool-1-uuid' },
        { source_asset: 'example-well-uuid-B1', target_asset: 'tube-0', submission: 'pool-1-uuid' },
        { source_asset: 'example-well-uuid-C1', target_asset: 'tube-0', submission: 'pool-1-uuid' },
        { source_asset: 'example-well-uuid-A2', target_asset: 'tube-1', submission: 'pool-2-uuid' },
        { source_asset: 'example-well-uuid-D1', target_asset: 'tube-1', submission: 'pool-2-uuid' },
        { source_asset: 'example-well-uuid-E1', target_asset: 'tube-1', submission: 'pool-2-uuid' },
        { source_asset: 'example-well-uuid-F1', target_asset: 'tube-1', submission: 'pool-2-uuid' },
        { source_asset: 'example-well-uuid-G1', target_asset: 'tube-1', submission: 'pool-2-uuid' },
        { source_asset: 'example-well-uuid-H1', target_asset: 'tube-1', submission: 'pool-2-uuid' }
      ]
    end

    before { stub_plate(parent_plate, stub_search: false) }

    context 'without parent metadata' do
      before do
        expect_specific_tube_creation
        expect_transfer_request_collection_creation
      end

      it 'pools by submission' do
        expect(subject.save!).to be_truthy
      end

      it 'sets the correct tube name' do
        expect(subject.save!).to be_truthy
        expect(subject.child_stock_tubes.length).to eq(2)
        expect(subject.child_stock_tubes).to have_key(child_1_name)
        expect(subject.child_stock_tubes).to have_key(child_2_name)
      end
    end

    context 'with parent metadata' do
      let(:child_1_name) { 'DN8 A1:C1' }
      let(:child_2_name) { 'DN8 D1:A2' }

      let(:stock_plate) { create(:stock_plate_for_plate, barcode_number: 8) }
      let(:parent_plate) do
        create(
          :plate_with_metadata,
          :has_pooling_metadata,
          uuid: parent_uuid,
          pool_sizes: [3, 6],
          well_states: ['passed'] * 9,
          well_uuid_result: 'example-well-uuid-%s',
          for_multiplexing: true,
          stock_plate: stock_plate
        )
      end

      it 'sets the correct tube name' do
        expect_specific_tube_creation
        expect_transfer_request_collection_creation

        expect(subject.save!).to be_truthy
        expect(subject.child_stock_tubes.length).to eq(2)
        expect(subject.child_stock_tubes).to have_key(child_1_name)
        expect(subject.child_stock_tubes).to have_key(child_2_name)
      end
    end

    context 'with a failed well' do
      let(:transfer_requests_attributes) do
        [
          { source_asset: 'example-well-uuid-A1', target_asset: 'tube-0', submission: 'pool-1-uuid' },
          { source_asset: 'example-well-uuid-C1', target_asset: 'tube-0', submission: 'pool-1-uuid' },
          { source_asset: 'example-well-uuid-A2', target_asset: 'tube-1', submission: 'pool-2-uuid' },
          { source_asset: 'example-well-uuid-D1', target_asset: 'tube-1', submission: 'pool-2-uuid' },
          { source_asset: 'example-well-uuid-E1', target_asset: 'tube-1', submission: 'pool-2-uuid' },
          { source_asset: 'example-well-uuid-F1', target_asset: 'tube-1', submission: 'pool-2-uuid' },
          { source_asset: 'example-well-uuid-G1', target_asset: 'tube-1', submission: 'pool-2-uuid' },
          { source_asset: 'example-well-uuid-H1', target_asset: 'tube-1', submission: 'pool-2-uuid' }
        ]
      end

      before { parent_plate.wells[1].state = 'failed' }

      it 'pools by submission' do
        expect_specific_tube_creation
        expect_transfer_request_collection_creation

        expect(subject.save!).to be_truthy
      end
    end

    context 'with previously passed requests' do
      let(:parent_plate) do
        create(
          :plate_with_metadata,
          :has_pooling_metadata,
          uuid: parent_uuid,
          pool_sizes: [3, 6],
          well_states: ['passed'] * 9,
          well_uuid_result: 'example-well-uuid-%s',
          pool_for_multiplexing: [true, false],
          stock_plate: stock_plate
        )
      end

      let(:transfer_requests_attributes) do
        [
          { source_asset: 'example-well-uuid-A1', target_asset: 'tube-0', submission: 'pool-1-uuid' },
          { source_asset: 'example-well-uuid-B1', target_asset: 'tube-0', submission: 'pool-1-uuid' },
          { source_asset: 'example-well-uuid-C1', target_asset: 'tube-0', submission: 'pool-1-uuid' }
        ]
      end

      let(:tube_attributes) { [{ name: child_1_name }] }

      it 'pools by submission' do
        expect_specific_tube_creation
        expect_transfer_request_collection_creation

        expect(subject.save!).to be_truthy
      end
    end
  end
end
