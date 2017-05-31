# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

# Parent in a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
describe LabwareCreators::PooledTubesBySubmission do
  it_behaves_like 'it only allows creation from tagged plates'

  subject do
    LabwareCreators::PooledTubesBySubmission.new(form_attributes)
  end

  # Set up our templates
  before do
    LabwareCreators::PooledTubesBySubmission.default_transfer_template_uuid = 'transfer-to-wells-by-submission-uuid'
  end

  let(:user_uuid)    { SecureRandom.uuid }
  let(:user)         { json :user, uuid: user_uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose)      { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid)  { SecureRandom.uuid }
  let(:parent)       { json :plate, uuid: parent_uuid, pool_sizes: [3, 3] }

  let(:form_attributes) do
    {
      user_uuid: user_uuid,
      purpose_uuid: purpose_uuid,
      parent_uuid: parent_uuid,
      api: api
    }
  end

  let(:wells_json) { json :well_collection, size: 6 }

  context '#save!' do
    has_a_working_api

    # Used to fetch the pools. This is the kind of thing we could pass through from a custom form
    let!(:parent_request) do
      stub_api_get(parent_uuid, body: parent)
      stub_api_get(parent_uuid,'wells',body: wells_json)
    end

    let(:tube_creation_request_uuid) { SecureRandom.uuid }

    let!(:tube_creation_request) do
      stub_api_post(
        'specific_tube_creations',
        payload: { specific_tube_creation: { user: user_uuid, parent: parent_uuid, child_purposes: [purpose_uuid, purpose_uuid] } },
        body: json(:specific_tube_creation, uuid: tube_creation_request_uuid, children_count: 2)
      )
    end

    # Find out what tubes we've just made!
    let!(:tube_creation_children_request) do
      stub_api_get(tube_creation_request_uuid, 'children', body: json(:tube_collection))
    end

    let!(:transfer_creation_request) do
      stub_api_post('transfer_request_collections',
                    payload: { transfer_request_collection: {
                      user: user_uuid,
                      transfer_requests: [
                        {'source_asset' => 'example-well-uuid-0', 'target_asset' => 'tube-0'},
                        {'source_asset' => 'example-well-uuid-1', 'target_asset' => 'tube-0'},
                        {'source_asset' => 'example-well-uuid-2', 'target_asset' => 'tube-0'},
                        {'source_asset' => 'example-well-uuid-3', 'target_asset' => 'tube-1'},
                        {'source_asset' => 'example-well-uuid-4', 'target_asset' => 'tube-1'},
                        {'source_asset' => 'example-well-uuid-5', 'target_asset' => 'tube-1'}
                      ]
                    } },
                    body: '{}')
    end

    it 'pools by submission' do
      expect(subject.save!).to be_truthy
      expect(tube_creation_request).to have_been_made.once
      expect(transfer_creation_request).to have_been_made.once
    end
  end
end
