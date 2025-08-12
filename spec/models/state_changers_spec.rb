# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateChangers do
  let(:plate_uuid) { SecureRandom.uuid }
  let(:labware_uuid) { SecureRandom.uuid }
  let(:user_uuid) { SecureRandom.uuid }
  let(:reason) { 'Because I want to' }
  let(:customer_accepts_responsibility) { false }

  shared_context 'common setup' do
    before do
      expect_api_v2_posts(
        'StateChange',
        [
          {
            contents: coordinates_to_pass,
            customer_accepts_responsibility: customer_accepts_responsibility,
            reason: reason,
            target_state: target_state,
            target_uuid: labware_uuid,
            user_uuid: user_uuid
          }
        ]
      )
    end
  end

  shared_examples 'a state changer' do
    it 'generates a state change' do
      subject.move_to!(target_state, reason, customer_accepts_responsibility)
    end
  end

  describe StateChangers::PlateStateChanger do
    has_a_working_api
    subject { described_class.new(api, labware_uuid, user_uuid) }

    include_context 'common setup'

    let(:plate) { create :v2_plate, uuid: labware_uuid, state: plate_state }
    let(:failed_wells) { {} }

    context 'when labware is a plate' do
      before do
        plate.wells.each { |well| well.state = 'failed' if failed_wells.include?(well.location) }
        stub_v2_plate(plate, stub_search: false)
      end

      context 'on a fully pending plate' do
        let(:plate_state) { 'pending' }
        let(:target_state) { 'passed' }
        let(:coordinates_to_pass) { nil }

        it_behaves_like 'a state changer'
      end

      context 'on a fully passed plate' do
        # if no wells are failed we leave contents blank and state changer assumes full plate
        let(:coordinates_to_pass) { nil }

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
        let(:coordinates_to_pass) { WellHelpers.column_order - failed_wells }

        it_behaves_like 'a state changer'
      end
    end
  end

  describe StateChangers::AutomaticPlateStateChanger do
    subject { described_class.new(api, labware_uuid, user_uuid) }

    include_context 'common setup'

    has_a_working_api

    let(:plate_state) { 'pending' }
    let!(:plate) { create :v2_plate_for_aggregation, uuid: plate_uuid, state: plate_state }
    let(:target_state) { 'passed' }
    let(:coordinates_to_pass) { nil }
    let(:plate_purpose_name) { 'Limber Bespoke Aggregation' }
    let(:work_completions_attributes) do
      [{ submission_uuids: %w[pool-1-uuid pool-2-uuid], target_uuid: plate_uuid, user_uuid: user_uuid }]
    end

    before { stub_v2_plate(plate, stub_search: false, custom_query: [:plate_for_completion, labware_uuid]) }

    context 'when config request type matches in progress submissions' do
      before { create :aggregation_purpose_config, uuid: plate.purpose.uuid, name: plate_purpose_name }

      it 'changes plate state and triggers a work completion' do
        expect_work_completion_creation

        subject.move_to!(target_state, reason, customer_accepts_responsibility)
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
        do_not_expect_work_completion_creation

        subject.move_to!(target_state, reason, customer_accepts_responsibility)
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
        expect_work_completion_creation

        subject.move_to!(target_state, reason, customer_accepts_responsibility)
      end
    end
  end

  describe StateChangers::TubeRackStateChanger do
    has_a_working_api

    subject { described_class.new(api, labware_uuid, user_uuid) }

    let(:tube_starting_state) { 'pending' }
    let(:tube_cancelled_state) { 'cancelled' }

    let(:target_state) { 'passed' }

    let(:tube1_uuid) { SecureRandom.uuid }
    let(:tube2_uuid) { SecureRandom.uuid }
    let(:tube3_uuid) { SecureRandom.uuid }

    let(:tube1) do
      create :v2_tube, uuid: tube1_uuid, state: tube_starting_state, barcode_number: 1, purpose_uuid: tube1_uuid
    end
    let(:tube2) do
      create :v2_tube, uuid: tube2_uuid, state: tube_cancelled_state, barcode_number: 2, purpose_uuid: tube1_uuid
    end

    let!(:tube_rack) { create :tube_rack, barcode_number: 4, uuid: labware_uuid }

    let(:racked_tube1) { create :racked_tube, coordinate: 'A1', tube: tube1, tube_rack: tube_rack }
    let(:racked_tube2) { create :racked_tube, coordinate: 'B1', tube: tube2, tube_rack: tube_rack }

    let(:labware) { tube_rack }

    before do
      stub_v2_tube_rack(tube_rack)
      create(:tube_config, uuid: tube1_uuid, name: 'example-purpose')
    end

    context 'when all tubes are in failed state' do
      before { allow(labware).to receive(:racked_tubes).and_return([tube3_uuid]) }

      it 'does not call move_to' do
        expect(subject).not_to receive(:move_to!)
      end
    end

    context 'when some tubes are not in failed state' do
      before do
        expect_api_v2_posts(
          'StateChange',
          [
            {
              contents: nil,
              customer_accepts_responsibility: customer_accepts_responsibility,
              reason: reason,
              target_state: target_state,
              target_uuid: labware_uuid,
              user_uuid: user_uuid
            }
          ]
        )
        allow(labware).to receive(:racked_tubes).and_return([racked_tube1, racked_tube2])
      end

      it 'returns the coordinates of tubes not in failed state' do
        subject.move_to!(target_state, reason, customer_accepts_responsibility)
      end
    end
  end

  describe StateChangers::TubeStateChanger do
    has_a_working_api
    subject { described_class.new(api, labware_uuid, user_uuid) }

    include_context 'common setup'

    let(:tube) { json :tube, uuid: labware_uuid, state: tube_state }
    let(:well_collection) { json :well_collection, default_state: tube_state, custom_state: failed_wells }
    let(:failed_wells) { {} }

    context 'on a fully pending tube' do
      let(:target_state) { 'passed' }
      let(:coordinates_to_pass) { nil } # tubes don't have wells

      it_behaves_like 'a state changer'
    end

    context 'on a fully passed tube' do
      # Ideally we wouldn't need this query here, but we don't know that
      # until we perform it.
      before do
        stub_api_get(labware_uuid, body: tube)
        stub_api_get(labware_uuid, 'wells', body: well_collection)
      end

      # if no wells are failed we leave contents blank and state changer assumes full tube
      let(:coordinates_to_pass) { nil }

      let(:tube_state) { 'passed' }
      let(:target_state) { 'qc_complete' }

      it_behaves_like 'a state changer'
    end

    context 'on a partially failed tube' do
      let(:tube_state) { 'passed' }

      # this triggers the FILTER_FAILS_ON check so contents is generated and failed wells are excluded
      let(:target_state) { 'qc_complete' }

      # when some wells are failed we filter those out of the contents
      let(:failed_wells) { { 'A1' => 'failed', 'D1' => 'failed' } }
      let(:coordinates_to_pass) { nil } # tubes don't have wells

      before do
        stub_api_get(labware_uuid, body: tube)
        stub_api_get(labware_uuid, 'wells', body: well_collection)
      end

      it_behaves_like 'a state changer'
    end
  end
end
