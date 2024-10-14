# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

# Parent is a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
RSpec.describe LabwareCreators::PooledTubesBySubmission do
  include FeatureHelpers

  has_a_working_api

  it_behaves_like 'it only allows creation from charged and passed plates with defined downstream pools'

  subject { LabwareCreators::PooledTubesBySubmission.new(api, form_attributes) }

  let(:user_uuid) { SecureRandom.uuid }

  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose) { json :purpose, uuid: purpose_uuid }

  let(:parent_uuid) { SecureRandom.uuid }
  let(:parent) { json :plate, uuid: parent_uuid, pool_sizes: [3, 6], stock_plate_barcode: 5, for_multiplexing: true }
  let(:source_plate) { create :v2_plate, uuid: parent_uuid }

  let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid: } }

  let(:wells_json) { json :well_collection, size: 9, default_state: 'passed' }

  before { stub_v2_plate(source_plate, stub_search: false) }

  context '#save!' do
    def expect_specific_tube_creation(child_tubes)
      # Create a mock for the specific tube creation.
      specific_tube_creation = double
      allow(specific_tube_creation).to receive(:children).and_return(child_tubes)

      # Expect the post request and return the mock.
      expect_api_v2_posts(
        'SpecificTubeCreation',
        [
          {
            child_purpose_uuids: [purpose_uuid] * child_tubes.size,
            parent_uuids: [parent_uuid],
            tube_attributes: child_tubes.map { |tube| { name: tube.name } },
            user_uuid: user_uuid
          }
        ],
        [specific_tube_creation]
      )
    end

    # Used to fetch the pools. This is the kind of thing we could pass through from a custom form
    let!(:parent_request) do
      stub_api_get(parent_uuid, body: parent)
      stub_api_get(parent_uuid, 'wells', body: wells_json)
    end

    let(:child_1_name) { 'DN5 A1:C1' }
    let(:child_2_name) { 'DN5 D1:A2' }

    let(:tube_attributes) { [{ name: child_1_name }, { name: child_2_name }] }

    let(:child_tubes) do
      # Prepare child tubes and stub their lookups.
      child_tubes =
        tube_attributes.each_with_index.map do |attrs, index|
          create(:v2_tube, name: attrs[:name], uuid: "tube-#{index}")
        end
      child_tubes.each { |child_tube| stub_v2_labware(child_tube) }

      child_tubes
    end

    let(:transfer_requests) do
      [
        { 'source_asset' => 'example-well-uuid-0', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' },
        { 'source_asset' => 'example-well-uuid-1', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' },
        { 'source_asset' => 'example-well-uuid-2', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' },
        { 'source_asset' => 'example-well-uuid-8', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' },
        { 'source_asset' => 'example-well-uuid-3', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' },
        { 'source_asset' => 'example-well-uuid-4', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' },
        { 'source_asset' => 'example-well-uuid-5', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' },
        { 'source_asset' => 'example-well-uuid-6', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' },
        { 'source_asset' => 'example-well-uuid-7', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' }
      ]
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

    context 'without parent metadata' do
      before { expect_specific_tube_creation(child_tubes) }

      it 'pools by submission' do
        expect(subject.save!).to be_truthy
        expect(transfer_creation_request).to have_been_made.once
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

      let(:parent) do
        json :plate_with_metadata,
             uuid: parent_uuid,
             pool_sizes: [3, 6],
             barcode_number: 10,
             stock_plate_barcode: 8,
             for_multiplexing: true
      end

      setup { stub_get_labware_metadata('DN10', parent, metadata: { stock_barcode: 'DN6' }) }

      it 'sets the correct tube name' do
        expect_specific_tube_creation(child_tubes)

        expect(subject.save!).to be_truthy
        expect(subject.child_stock_tubes.length).to eq(2)
        expect(subject.child_stock_tubes).to have_key(child_1_name)
        expect(subject.child_stock_tubes).to have_key(child_2_name)
      end
    end

    context 'with a failed well' do
      let(:wells_json) { json :well_collection, size: 9, default_state: 'passed', custom_state: { 'B1' => 'failed' } }
      let(:transfer_requests) do
        [
          { 'source_asset' => 'example-well-uuid-0', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' },
          { 'source_asset' => 'example-well-uuid-2', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' },
          { 'source_asset' => 'example-well-uuid-8', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' },
          { 'source_asset' => 'example-well-uuid-3', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' },
          { 'source_asset' => 'example-well-uuid-4', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' },
          { 'source_asset' => 'example-well-uuid-5', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' },
          { 'source_asset' => 'example-well-uuid-6', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' },
          { 'source_asset' => 'example-well-uuid-7', 'target_asset' => 'tube-1', 'submission' => 'pool-2-uuid' }
        ]
      end

      before { expect_specific_tube_creation(child_tubes) }

      it 'pools by submission' do
        expect(subject.save!).to be_truthy
        expect(transfer_creation_request).to have_been_made.once
      end
    end

    context 'with previously passed requests' do
      let(:parent) do
        json :plate, uuid: parent_uuid, pool_sizes: [3, 6], pool_for_multiplexing: [true, false], stock_plate_barcode: 5
      end

      let(:transfer_requests) do
        [
          { 'source_asset' => 'example-well-uuid-0', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' },
          { 'source_asset' => 'example-well-uuid-1', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' },
          { 'source_asset' => 'example-well-uuid-2', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' }
        ]
      end

      let(:tube_attributes) { [{ name: child_1_name }] }

      before { expect_specific_tube_creation(child_tubes) }

      it 'pools by submission' do
        expect(subject.save!).to be_truthy
        expect(transfer_creation_request).to have_been_made.once
      end
    end
  end
end
