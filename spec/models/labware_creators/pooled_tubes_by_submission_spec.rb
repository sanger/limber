# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

# Parent in a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
RSpec.describe LabwareCreators::PooledTubesBySubmission do
  it_behaves_like 'it only allows creation from charged and passed plates with defined downstream pools'

  subject do
    LabwareCreators::PooledTubesBySubmission.new(api, form_attributes)
  end

  let(:user_uuid)    { SecureRandom.uuid }
  let(:user)         { json :user, uuid: user_uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose)      { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid)  { SecureRandom.uuid }

  let(:parent)       { json :plate, uuid: parent_uuid, pool_sizes: [3, 6], stock_plate_barcode: 5, for_multiplexing: true }

  let(:form_attributes) do
    {
      user_uuid: user_uuid,
      purpose_uuid: purpose_uuid,
      parent_uuid: parent_uuid
    }
  end

  let(:wells_json) { json :well_collection, size: 9, default_state: 'passed' }

  context '#save!' do
    has_a_working_api

    # Used to fetch the pools. This is the kind of thing we could pass through from a custom form
    let!(:parent_request) do
      stub_api_get(parent_uuid, body: parent)
      stub_api_get(parent_uuid, 'wells', body: wells_json)
    end

    let(:creation_payload) do
      {
        user: user_uuid,
        parent: parent_uuid,
        child_purposes: [purpose_uuid, purpose_uuid],
        tube_attributes: [{ name: 'DN5 A1:C1' }, { name: 'DN5 D1:A2' }]
      }
    end

    let(:tube_creation_request_uuid) { SecureRandom.uuid }

    let!(:tube_creation_request) do
      stub_api_post(
        'specific_tube_creations',
        payload: {
          specific_tube_creation: creation_payload
        },
        body: json(:specific_tube_creation, uuid: tube_creation_request_uuid, children_count: 2, names: ['DN5 A1:C1', 'DN5 D1:A2'])
      )
    end

    # Find out what tubes we've just made!
    let!(:tube_creation_children_request) do
      stub_api_get(tube_creation_request_uuid, 'children', body: json(:tube_collection, names: ['DN5 A1:C1', 'DN5 D1:A2']))
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
      stub_api_post('transfer_request_collections',
                    payload: { transfer_request_collection: {
                      user: user_uuid,
                      transfer_requests: transfer_requests
                    } },
                    body: '{}')
    end

    it 'pools by submission' do
      expect(subject.save!).to be_truthy
      expect(tube_creation_request).to have_been_made.once
      expect(transfer_creation_request).to have_been_made.once
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
      it 'pools by submission' do
        expect(subject.save!).to be_truthy
        expect(transfer_creation_request).to have_been_made.once
      end
    end

    context 'with previously passed requests' do
      let(:parent) { json :plate, uuid: parent_uuid, pool_sizes: [3, 6], pool_for_multiplexing: [true, false], stock_plate_barcode: 5 }

      let(:transfer_requests) do
        [
          { 'source_asset' => 'example-well-uuid-0', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' },
          { 'source_asset' => 'example-well-uuid-1', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' },
          { 'source_asset' => 'example-well-uuid-2', 'target_asset' => 'tube-0', 'submission' => 'pool-1-uuid' }
        ]
      end

      let(:creation_payload) do
        {
          user: user_uuid,
          parent: parent_uuid,
          child_purposes: [purpose_uuid],
          tube_attributes: [{ name: 'DN5 A1:C1' }]
        }
      end

      it 'pools by submission' do
        expect(subject.save!).to be_truthy
        expect(transfer_creation_request).to have_been_made.once
      end
    end
  end
end
