# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

# CreationForm is the base class for our forms
describe LabwareCreators::FinalTubeFromPlate do
  it_behaves_like 'it only allows creation from charged and passed plates'

  subject do
    LabwareCreators::FinalTubeFromPlate.new(form_attributes)
  end

  # Set up our templates
  before do
    LabwareCreators::FinalTubeFromPlate.default_transfer_template_uuid = 'transfer-to-mx-tubes-on-submission'
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
      stub_api_get(parent_uuid, body: parent)
    end

    # The API needs to pull back the transfer template to know what actions it can perform
    let!(:transfer_template_request) do
      stub_api_get('transfer-to-mx-tubes-on-submission', body: json(:transfer_wells_to_mx_library_tubes_by_submission))
    end

    let!(:transfer_creation_request) do
      stub_api_post('transfer-to-mx-tubes-on-submission',
                    payload: { transfer: {
                      source: parent_uuid,
                      user: user_uuid
                    } },
                    body: json(:transfer_to_mx_tubes_by_submission))
    end

    let!(:tube_state_change_request_0) do
      stub_api_post(
        'state_changes',
        payload: {
          'state_change' => {
            user: user_uuid,
            target: 'child-tube-0',
            target_state: 'passed'
          }
        },
        body: '{}' # We don't care about the response
      )
    end
    let!(:tube_state_change_request_1) do
      stub_api_post(
        'state_changes',
        payload: {
          'state_change' => {
            user: user_uuid,
            target: 'child-tube-1',
            target_state: 'passed'
          }
        },
        body: '{}' # We don't care about the response
      )
    end

    it 'pools by submission' do
      expect(subject.save!).to be_truthy
      expect(transfer_creation_request).to have_been_made.once
    end

    it 'passes the tubes automatically' do
      subject.save!
      expect(tube_state_change_request_0).to have_been_made.once
      expect(tube_state_change_request_1).to have_been_made.once
    end

    it 'redirects to the parent plate' do
      subject.save!
      expect(subject.child.uuid).to eq(parent_uuid)
    end
  end
end
