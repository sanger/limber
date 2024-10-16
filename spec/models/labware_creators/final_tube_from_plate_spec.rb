# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

# CreationForm is the base class for our forms
RSpec.describe LabwareCreators::FinalTubeFromPlate do
  it_behaves_like 'it only allows creation from charged and passed plates with defined downstream pools'

  subject { LabwareCreators::FinalTubeFromPlate.new(api, form_attributes) }

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose) { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid) { SecureRandom.uuid }
  let(:parent) { json :plate, uuid: parent_uuid, pool_sizes: [3, 3] }

  let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid: } }

  context '#save!' do
    has_a_working_api

    # Used to fetch the pools. This is the kind of thing we could pass through from a custom form
    let!(:parent_request) { stub_api_get(parent_uuid, body: parent) }

    let(:destination_tubes) { create_list :v2_tube, 2 }
    let(:transfer) { create :v2_transfer_to_tubes_by_submission, tubes: destination_tubes }
    let(:transfers_attributes) do
      [
        {
          arguments: {
            user_uuid: user_uuid,
            source_uuid: parent_uuid,
            transfer_template_uuid: 'transfer-to-mx-tubes-on-submission'
          },
          response: transfer
        }
      ]
    end

    let(:state_changes_attributes) do
      [
        { target_state: 'passed', target_uuid: destination_tubes[0].uuid, user_uuid: user_uuid },
        { target_state: 'passed', target_uuid: destination_tubes[1].uuid, user_uuid: user_uuid }
      ]
    end

    before do
      stub_api_v2_post('Transfer', transfer)
      stub_api_v2_post('StateChange')
    end

    it 'pools by submission' do
      expect_transfer_creation

      expect(subject.save!).to be_truthy
    end

    it 'passes the tubes automatically' do
      expect_state_change_creation

      subject.save!
    end

    it 'redirects to the parent plate' do
      subject.save!

      expect(subject.redirection_target.uuid).to eq(parent_uuid)
    end
  end
end
