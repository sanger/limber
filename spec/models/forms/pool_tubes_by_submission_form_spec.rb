# frozen_string_literal: true
require 'spec_helper'
require 'forms/creation_form'

# CreationForm is the base class for our forms
describe Forms::PoolTubesBySubmissionForm do
  subject do
    Forms::PoolTubesBySubmissionForm.new(form_attributes)
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

    let(:tube_creation_request) do
      stub_request(:post, 'http://example.com:3000/specific_tube_creation')
        .with(
          headers: { 'Accept' => 'application/json', 'content-type' => 'application/json' },
          body: { user: user_uuid, parent: parent_uuid, child_purposes: [purpose_uuid, purpose_uuid] }
        )
        .to_return(status: 200, body: '{}', headers: {})
    end

    let(:transfer_creation_request) do
      stub_request(:post, 'http://example.com:3000/transfer-to-wells-by-submission-uuid')
        .with(
          headers: { 'Accept' => 'application/json', 'content-type' => 'application/json' },
          body: {}
        )
        .to_return(status: 200, body: '{}', headers: {})
    end

    it 'pools by submission' do
      expect(subject.save!).to be_truthy
      expect(tube_creation_request).to have_been_made.once
      expect(transfer_creation_request).to have_been_made.once
    end
  end
end
