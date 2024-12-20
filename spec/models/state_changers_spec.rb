# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateChangers::DefaultStateChanger do
  has_a_working_api

  let(:plate_uuid) { SecureRandom.uuid }
  let(:plate) { create(:v2_plate, uuid: plate_uuid, state: plate_state) }
  let(:failed_wells) { [] }
  let(:user_uuid) { SecureRandom.uuid }
  let(:reason) { 'Because I want to' }
  let(:customer_accepts_responsibility) { false }
  let(:state_changes_attributes) do
    [
      {
        contents: wells_to_pass,
        customer_accepts_responsibility: customer_accepts_responsibility,
        reason: reason,
        target_state: target_state,
        target_uuid: plate_uuid,
        user_uuid: user_uuid
      }
    ]
  end

  subject { StateChangers::DefaultStateChanger.new(api, plate_uuid, user_uuid) }

  describe '#move_to!' do
    before do
      expect_state_change_creation
      plate.wells.each { |well| well.state = 'failed' if failed_wells.include?(well.location) }
      stub_v2_plate(plate, stub_search: false)
    end

    shared_examples 'a state changer' do
      it 'generates a state change' do
        subject.move_to!(target_state, reason, customer_accepts_responsibility)
      end
    end

    context 'on a fully pending plate' do
      let(:plate_state) { 'pending' }
      let(:target_state) { 'passed' }
      let(:wells_to_pass) { nil }
      it_behaves_like 'a state changer'
    end

    context 'on a fully passed plate' do
      # if no wells are failed we leave contents blank and state changer assumes full plate
      let(:wells_to_pass) { nil }

      let(:plate_state) { 'passed' }
      let(:target_state) { 'qc_complete' }

      it_behaves_like 'a state changer'
    end

    context 'on a partially failed plate' do
      let(:plate_state) { 'passed' }

      # this triggers the FILTER_FAILS_ON check so contents is generated and failed wells are excluded
      let(:target_state) { 'qc_complete' }

      # when some wells are failed we filter those out of the contents
      let(:failed_wells) { %w[A1 D1] }
      let(:wells_to_pass) { WellHelpers.column_order - failed_wells }

      it_behaves_like 'a state changer'
    end

    context 'on use of an automated plate state changer' do
      let(:plate_state) { 'pending' }
      let!(:plate) { create :v2_plate_for_aggregation, uuid: plate_uuid, state: plate_state }
      let(:target_state) { 'passed' }
      let(:wells_to_pass) { nil }
      let(:plate_purpose_name) { 'Limber Bespoke Aggregation' }
      let(:work_completion_request) do
        { 'work_completion' => { target: plate_uuid, submissions: %w[pool-1-uuid pool-2-uuid], user: user_uuid } }
      end
      let(:work_completion) { json :work_completion }
      let!(:work_completion_creation) do
        stub_api_post('work_completions', payload: work_completion_request, body: work_completion)
      end

      subject { StateChangers::AutomaticPlateStateChanger.new(api, plate_uuid, user_uuid) }

      before { stub_v2_plate(plate, stub_search: false, custom_query: [:plate_for_completion, plate_uuid]) }

      context 'when config request type matches in progress submissions' do
        before { create :aggregation_purpose_config, uuid: plate.purpose.uuid, name: plate_purpose_name }

        it 'changes plate state and triggers a work completion' do
          subject.move_to!(target_state, reason, customer_accepts_responsibility)

          expect(work_completion_creation).to have_been_made.once
        end
      end

      context 'when config request type does not match in progress submissions' do
        before do
          create :aggregation_purpose_config,
                 uuid: plate.purpose.uuid,
                 name: plate_purpose_name,
                 work_completion_request_type: 'not_matching_type'
        end

        it 'changes plate state but does not trigger a work completion' do
          subject.move_to!(target_state, reason, customer_accepts_responsibility)

          expect(work_completion_creation).to_not have_been_made
        end
      end

      # The ability to have multiple request types in the config was added for scRNA Core pipeline.
      # The expectation was that any one plate would only have one of the request types on it,
      # so I haven't tested a plate with a mix of request types.
      context 'when one of the multiple config request types matches the in progress submissions' do
        before do
          create :aggregation_purpose_config,
                 uuid: plate.purpose.uuid,
                 name: plate_purpose_name,
                 work_completion_request_type: %w[limber_bespoke_aggregation another_request_type]
        end

        it 'changes plate state and triggers a work completion' do
          subject.move_to!(target_state, reason, customer_accepts_responsibility)

          expect(work_completion_creation).to have_been_made.once
        end
      end
    end
  end
end
