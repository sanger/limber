# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateChangers do
  has_a_working_api

  let(:plate_uuid) { SecureRandom.uuid }
  let(:plate) { json :plate, uuid: plate_uuid, state: plate_state }
  let(:well_collection) { json :well_collection, default_state: plate_state, custom_state: failed_wells }
  let(:failed_wells) { {} }

  let(:tube_uuid) { SecureRandom.uuid }
  let(:tube) { json :tube, uuid: tube_uuid, state: tube_state }

  let(:user_uuid) { SecureRandom.uuid }
  let(:reason) { 'Because I want to' }
  let(:customer_accepts_responsibility) { false }

  shared_examples 'a state changer' do
    it 'generates a state change' do
      subject.move_to!(target_state, reason, customer_accepts_responsibility)
    end
  end

  shared_examples 'a plate state changer' do
    describe '#move_to!' do
      before do
        expect_api_v2_posts(
          'StateChange',
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
        )
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
        let(:failed_wells) { { 'A1' => 'failed', 'D1' => 'failed' } }
        let(:wells_to_pass) { WellHelpers.column_order - failed_wells.keys }

        before do
          stub_api_get(plate_uuid, body: plate)
          stub_api_get(plate_uuid, 'wells', body: well_collection)
        end

        it_behaves_like 'a state changer'
      end
    end
  end

  shared_examples 'a tube state changer' do
    describe '#move_to!' do
      before do
        expect_api_v2_posts(
          'StateChange',
          [
            {
              contents: wells_to_pass,
              customer_accepts_responsibility: customer_accepts_responsibility,
              reason: reason,
              target_state: target_state,
              target_uuid: tube_uuid,
              user_uuid: user_uuid
            }
          ]
        )
      end

      context 'on a pending tube' do
        let(:tube_state) { 'pending' }
        let(:target_state) { 'passed' }
        let(:wells_to_pass) { nil } # tubes don't have wells
        it_behaves_like 'a state changer'
      end

      context 'on a passed tube' do
        let(:tube_state) { 'passed' }
        let(:target_state) { 'qc_complete' }
        let(:wells_to_pass) { nil } # tubes don't have wells
        it_behaves_like 'a state changer'
      end
    end
  end

  shared_examples 'an automated plate state changer' do
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

    before do
      expect_api_v2_posts(
        'StateChange',
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
      )
    end
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

  describe StateChangers::PlateStateChanger do
    subject { StateChangers::PlateStateChanger.new(api, plate_uuid, user_uuid) }
    it_behaves_like 'a plate state changer'
  end

  describe StateChangers::AutomaticPlateStateChanger do
    subject { StateChangers::AutomaticPlateStateChanger.new(api, plate_uuid, user_uuid) }
    it_behaves_like 'an automated plate state changer'
  end

  describe StateChangers::TubeStateChanger do
    subject { StateChangers::TubeStateChanger.new(api, tube_uuid, user_uuid) }
    it_behaves_like 'a tube state changer'
  end
end
