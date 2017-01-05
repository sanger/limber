# frozen_string_literal: true
require 'spec_helper'
require 'forms/creation_form'

# CreationForm is the base class for our forms
describe Forms::PoolTubesBySubmissionForm do
  subject do
    Forms::PoolTubesBySubmissionForm.new(form_attributes)
  end

  # Set up our templates
  before(:each) do
    Forms::PoolTubesBySubmissionForm.default_transfer_template_uuid = 'transfer-to-wells-by-submission-uuid'
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

  context '#save!' do
    has_a_working_api

     # Used to fetch the pools. This is the kind of thing we could pass through from a custom form
    let!(:parent_request) do
      stub_request(:get, api_url_for(parent_uuid))
        .to_return(status: 200, body: parent, headers: {'content-type' => 'application/json'})
    end

    let(:tube_creation_request_uuid) { SecureRandom.uuid }

    let!(:tube_creation_request) do
      stub_request(:post, api_url_for('specific_tube_creations'))
        .with(
          headers: { 'Accept' => 'application/json', 'content-type' => 'application/json' },
          body: { specific_tube_creation: { user: user_uuid, parent: parent_uuid, child_purposes: [purpose_uuid, purpose_uuid] } }
        )
        .to_return(
          status: 201,
          body: json(:specific_tube_creation, uuid: tube_creation_request_uuid, children_count: 2),
          headers: {'content-type' => 'application/json'}
        )
    end

    # Find out what tubes we've just made!
    let!(:tube_creation_children_request) do
      stub_request(:get, api_url_for(tube_creation_request_uuid, 'children'))
        .to_return(status: 200, body: json(:tube_collection), headers: {'content-type' => 'application/json'})
    end

    # The API needs to pull back the transfer template to know what actions it can perform
    let!(:transfer_template_request) do
      stub_request(:get, 'http://example.com:3000/transfer-to-wells-by-submission-uuid')
        .to_return(status: 200, body: json(:transfer_to_specific_tubes_by_submission), headers: { 'content-type' => 'application/json' })
    end

    let!(:transfer_creation_request) do
      stub_request(:post, 'http://example.com:3000/transfer-to-wells-by-submission-uuid')
        .with(
          headers: { 'Accept' => 'application/json', 'content-type' => 'application/json' },
          body: { transfer: {
            targets: { 'pool-1-uuid' => 'tube-0', 'pool-2-uuid' => 'tube-1' },
            source: parent_uuid,
            user: user_uuid
          }}
        )
        .to_return(status: 200, body: '{}', headers: { 'content-type' => 'application/json' })
    end

    it 'pools by submission' do
      expect(subject.save!).to be_truthy
      expect(tube_creation_request).to have_been_made.once
      expect(transfer_creation_request).to have_been_made.once
    end
  end
end
