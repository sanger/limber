# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateChangers do
  let(:labware_uuid) { SecureRandom.uuid }
  let(:user_uuid) { SecureRandom.uuid }
  let(:reason) { 'Because I want to' }
  let(:customer_accepts_responsibility) { false }

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

  shared_examples 'a state changer' do
    it 'generates a state change' do
      subject.move_to!(target_state, reason, customer_accepts_responsibility)
    end
  end

  describe StateChangers::PlateStateChanger do
    has_a_working_api

    let(:plate) { json :plate, uuid: labware_uuid, state: plate_state }
    let(:well_collection) { json :well_collection, default_state: plate_state, custom_state: failed_wells }
    let(:failed_wells) { {} }
    subject { StateChangers::PlateStateChanger.new(api, labware_uuid, user_uuid) }

    context 'on a fully pending plate' do
      let(:plate_state) { 'pending' }
      let(:target_state) { 'passed' }
      let(:coordinates_to_pass) { nil }
      it_behaves_like 'a state changer'
    end

    context 'on a fully passed plate' do
      # Ideally we wouldn't need this query here, but we don't know that
      # until we perform it.
      before do
        stub_api_get(labware_uuid, body: plate)
        stub_api_get(labware_uuid, 'wells', body: well_collection)
      end

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
      let(:failed_wells) { { 'A1' => 'failed', 'D1' => 'failed' } }
      let(:coordinates_to_pass) { WellHelpers.column_order - failed_wells.keys }

      before do
        stub_api_get(labware_uuid, body: plate)
        stub_api_get(labware_uuid, 'wells', body: well_collection)
      end

      it_behaves_like 'a state changer'
    end
  end

  describe StateChangers::AutomaticPlateStateChanger do
    has_a_working_api

    let(:plate_state) { 'pending' }
    let!(:plate) { create :v2_plate_for_aggregation, uuid: labware_uuid, state: plate_state }
    let(:target_state) { 'passed' }
    let(:coordinates_to_pass) { nil }
    let(:plate_purpose_name) { 'Limber Bespoke Aggregation' }
    let(:work_completion_request) do
      { 'work_completion' => { target: labware_uuid, submissions: %w[pool-1-uuid pool-2-uuid], user: user_uuid } }
    end
    let(:work_completion) { json :work_completion }
    let!(:work_completion_creation) do
      stub_api_post('work_completions', payload: work_completion_request, body: work_completion)
    end

    subject { StateChangers::AutomaticPlateStateChanger.new(api, labware_uuid, user_uuid) }

    before { stub_v2_plate(plate, stub_search: false, custom_query: [:plate_for_completion, labware_uuid]) }

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

  describe StateChangers::TubeRackStateChanger do
    has_a_working_api

    let(:tube_starting_state) { 'pending' }
    let(:tube_failed_state) { 'failed' }

    let(:target_state) { 'qc_complete' }

    let(:tube1_uuid) { SecureRandom.uuid }
    let(:tube2_uuid) { SecureRandom.uuid }
    let(:tube3_uuid) { SecureRandom.uuid }

    let(:tube1) { create :v2_tube, uuid: tube1_uuid, state: tube_failed_state, barcode_number: 1 }
    let(:tube2) { create :v2_tube, uuid: tube2_uuid, state: tube_starting_state, barcode_number: 2 }
    let(:tube3) { create :v2_tube, uuid: tube3_uuid, state: tube_starting_state, barcode_number: 3 }

    let!(:tube_rack) { create :tube_rack, barcode_number: 4, uuid: labware_uuid }

    let(:racked_tube1) { create :racked_tube, coordinate: 'A1', tube: tube1, tube_rack: tube_rack }
    let(:racked_tube2) { create :racked_tube, coordinate: 'B1', tube: tube2, tube_rack: tube_rack }
    let(:racked_tube3) { create :racked_tube, coordinate: 'C1', tube: tube3, tube_rack: tube_rack }

    let(:labware) { tube_rack }

    subject { StateChangers::TubeRackStateChanger.new(api, labware_uuid, user_uuid) }

    before do
      stub_v2_tube_rack(tube_rack)

      # allow(labware).to receive(:racked_tubes).and_return([racked_tube1, racked_tube2, racked_tube3])
    end

    context 'when all tubes are in failed state' do
      let(:coordinates_to_pass) { [] }

      before do
        # stub_v2_tube_rack(tube_rack)
        allow(labware).to receive(:racked_tubes).and_return([racked_tube1])
      end

      # if all the tubes are already in the target state expect contents to be empty
      # TODO: I'm not sure this is correct behaviour, it should probably raise an error
      # or a validation should catch that the state change is not needed
      it 'returns empty array' do
        expect(subject.contents_for(target_state)).to eq([])
        subject.move_to!(target_state, reason, customer_accepts_responsibility)
      end
    end

    context 'when some tubes are not in failed state' do
      let(:coordinates_to_pass) { %w[B1 C1] }

      before { allow(labware).to receive(:racked_tubes).and_return([racked_tube1, racked_tube2, racked_tube3]) }

      it 'returns the coordinates of tubes not in failed state' do
        expect(subject.contents_for(target_state)).to eq(%w[B1 C1])
        subject.move_to!(target_state, reason, customer_accepts_responsibility)
      end
    end
  end

  describe StateChangers::TubeStateChanger do
    has_a_working_api

    let(:tube) { json :tube, uuid: labware_uuid, state: tube_state }
    let(:well_collection) { json :well_collection, default_state: tube_state, custom_state: failed_wells }
    let(:failed_wells) { {} }
    subject { StateChangers::TubeStateChanger.new(api, labware_uuid, user_uuid) }

    context 'on a fully pending tube' do
      let(:tube_state) { 'pending' }
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
