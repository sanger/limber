# frozen_string_literal: true

require 'rails_helper'

describe StateChangers::DefaultStateChanger do
  has_a_working_api

  let(:plate_uuid) { SecureRandom.uuid }
  let(:plate)      { json :plate, uuid: plate_uuid, state: plate_state }
  let(:well_collection) { json :well_collection, default_state: plate_state, custom_state: failed_wells }
  let(:failed_wells) { {} }
  let(:user_uuid)  { SecureRandom.uuid }
  let(:reason)     { 'Because I want to' }
  let(:customer_accepts_responsibility) { false }
  subject { StateChangers::DefaultStateChanger.new(api, plate_uuid, user_uuid) }

  describe '#move_to!' do
    let!(:state_change_request) do
      stub_api_post(
        'state_changes',
        payload: { state_change: expected_parameters },
        body: '{}' # We don't care
      )
    end

    shared_examples 'a state changer' do
      it 'generates a state change' do
        subject.move_to!(target_state, reason, customer_accepts_responsibility)
      end
    end

    let(:expected_parameters) do
      {
        target: plate_uuid,
        user: user_uuid,
        target_state: target_state,
        reason: reason,
        customer_accepts_responsibility: customer_accepts_responsibility,
        contents: wells_to_pass
      }
    end

    context 'on a fully pending plate' do
      let(:plate_state) { 'pending' }
      let(:target_state) { 'passed' }
      let(:wells_to_pass) { nil }
      it_behaves_like 'a state changer'
    end

    context 'on a fully passed plate' do
      # Ideally we wouldn't need this query here, but we don't know that
      # until we perform it.
      before do
        stub_api_get(plate_uuid, body: plate)
        stub_api_get(plate_uuid, 'wells', body: well_collection)
      end
      let(:wells_to_pass) { WellHelpers.column_order }

      let(:plate_state) { 'passed' }
      let(:target_state) { 'qc_complete' }
      it_behaves_like 'a state changer'
    end

    context 'on a partially failed plate' do
      let(:plate_state) { 'passed' }
      let(:target_state) { 'qc_complete' }
      let(:failed_wells) { { 'A1' => 'failed', 'D1' => 'failed' } }
      let(:wells_to_pass) { WellHelpers.column_order - failed_wells.keys }

      before do
        stub_api_get(plate_uuid, body: plate)
        stub_api_get(plate_uuid, 'wells', body: well_collection)
      end

      it_behaves_like 'a state changer'
    end

    after do
      expect(state_change_request).to have_been_made.once
    end
  end
end
