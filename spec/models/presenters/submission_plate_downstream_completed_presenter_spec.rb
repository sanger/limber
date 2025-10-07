# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

DESCENDENT_TUBE_INCLUDES =
  'receptacle,aliquots,aliquots.request,aliquots.request.request_type,receptacle.requests_as_source.request_type'

RSpec.describe Presenters::SubmissionPlateDownstreamCompletedPresenter do
  subject(:presenter) { described_class.new(labware:) }

  let(:submission_study) { create :study, name: 'Submission Study' }
  let(:submission_project) { create :project, name: 'Submission Project' }

  # ancestor plate setup
  let(:sample1) { create(:sample) }
  let(:sample2) { create(:sample) }

  let(:ancestor_plate_purpose_name) { 'Ancestor Plate Purpose' }

  let(:tag_group1) { create(:tag_group, name: 'tg1') }
  let(:tag_group2) { create(:tag_group, name: 'tg2') }

  let(:tag1s) { (1..2).map { |i| create(:tag, map_id: i, tag_group: tag_group1) } }
  let(:tag2s) { (5..6).map { |i| create(:tag, map_id: i, tag_group: tag_group2) } }

  # aliquots for wells in the ancestor plate
  let(:ancestor_aliquot1) do
    create(
      :aliquot,
      sample: sample1,
      tag: tag1s[0],
      tag2: tag2s[0],
      study: submission_study,
      project: submission_project
    )
  end
  let(:ancestor_aliquot2) do
    create(
      :aliquot,
      sample: sample2,
      tag: tag1s[1],
      tag2: tag2s[1],
      study: submission_study,
      project: submission_project
    )
  end

  # states for requests and submissions
  let(:state_pending) { 'pending' }
  let(:state_started) { 'started' }
  let(:state_completed) { 'passed' }
  let(:state_cancelled) { 'cancelled' }

  # library prep submission and requests
  let(:library_type) { 'library-type' }
  let(:library_prep_submission) { create(:submission, state: 'completed') }

  let(:library_request1) do
    create(
      :library_request,
      library_type: library_type,
      submission: library_prep_submission,
      state: state_completed
    )
  end
  let(:library_request2) do
    create(
      :library_request,
      library_type: library_type,
      submission: library_prep_submission,
      state: state_completed
    )
  end

  # wells for the ancestor plate
  let(:ancestor_well1) do
    create(
      :well,
      study: submission_study,
      project: submission_project,
      aliquots: [ancestor_aliquot1],
      requests_as_source: [library_request1],
      location: 'A1'
    )
  end

  let(:ancestor_well2) do
    create(
      :well,
      study: submission_study,
      project: submission_project,
      aliquots: [ancestor_aliquot2],
      requests_as_source: [library_request2],
      location: 'B1'
    )
  end

  let(:ancestor_wells) { [ancestor_well1, ancestor_well2] }

  # create the ancestor plate with the two wells
  let(:ancestor_plate) do
    create(
      :plate,
      purpose_name: ancestor_plate_purpose_name,
      barcode_number: '1',
      size: 96,
      wells: ancestor_wells
    )
  end

  # current plate setup
  let(:current_plate_uuid) { 'current-plate-uuid' }
  let(:current_plate_purpose_uuid) { 'current-plate-purpose-uuid' }
  let(:current_plate_purpose_name) { 'current Plate Purpose' }

  # current plate aliquots
  let(:current_receptacle1_uuid) { 'current-receptacle1-uuid' }
  let(:current_receptacle2_uuid) { 'current-receptacle2-uuid' }

  let(:current_aliquot1) do
    create(
      :aliquot,
      sample: sample1,
      tag: tag1s[0],
      tag2: tag2s[0],
      request: library_request1,
      outer_request: library_request1,
      study: submission_study,
      project: submission_project
    )
  end
  let(:current_aliquot2) do
    create(
      :aliquot,
      sample: sample2,
      tag: tag1s[1],
      tag2: tag2s[1],
      request: library_request2,
      outer_request: library_request2,
      study: submission_study,
      project: submission_project
    )
  end

  # transfer requests from the ancestor to the current wells
  let(:transfer_request1) do
    create(
      :transfer_request,
      source_asset: ancestor_well1,
      target_asset: nil,
      submission: library_prep_submission,
      state: state_completed
    )
  end
  let(:transfer_request2) do
    create(
      :transfer_request,
      source_asset: ancestor_well2,
      target_asset: nil,
      submission: library_prep_submission,
      state: state_completed
    )
  end

  # wells for the current plate
  let(:current_well1) do
    create(
      :well_with_transfer_requests,
      aliquots: [current_aliquot1],
      location: 'A1',
      transfer_requests_as_source: [],
      transfer_requests_as_target: [transfer_request1]
    )
  end
  let(:current_well2) do
    create(
      :well_with_transfer_requests,
      aliquots: [current_aliquot2],
      location: 'B1',
      transfer_requests_as_source: [],
      transfer_requests_as_target: [transfer_request2]
    )
  end

  let(:current_wells) { [current_well1, current_well2] }

  # create the current plate with the ancestor plate as its stock plate
  let(:labware) do
    create :plate,
           uuid: current_plate_uuid,
           purpose_name: current_plate_purpose_name,
           purpose_uuid: current_plate_purpose_uuid,
           wells: current_wells,
           ancestors: [ancestor_plate],
           barcode_number: '2',
           state: 'passed',
           direct_submissions: []
  end

  let(:state) { 'passed' }

  before do
    # set up the purpose config for the current plate purpose
    create(:submission_plate_downstream_completed_purpose_config, uuid: labware.purpose.uuid)
  end

  # with no downstream tubes yet, we should behave like a standard labware presenter
  # and not allow the submission sidebar to be showm
  context 'without any downstream tubes' do
    it_behaves_like 'a labware presenter'

    let(:barcode_string) { 'DN2T' }
    let(:purpose_name) { labware.purpose.name }
    let(:title) { labware.purpose.name }

    # state of plate should be 'passed' as library prep is completed
    let(:expected_state) { state_completed }

    # sidebar should be the default one as submission cannot be made yet
    let(:sidebar_partial) { 'default' }

    let(:summary_tab) do
      [
        ['Barcode', barcode_string],
        ['Number of wells', '2/96'],
        ['Plate type', labware.purpose.name],
        ['Current plate state', expected_state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end

    it 'is handling wells from the same study' do
      labware.wells.each { |well| expect(well.aliquots.first.study).to eq(submission_study) }
    end

    it 'is handling wells from the same project' do
      labware.wells.each { |well| expect(well.aliquots.first.project).to eq(submission_project) }
    end

    it 'has no pending submissions' do
      expect(presenter.pending_submissions?).to be false
    end

    it 'displays the default sidebar' do
      expect(presenter.sidebar_partial).to eq('default')
    end
  end

  # with downstream tubes we check the requests and their states to determine if
  # the initial run has completed and if we can now allow submissions
  context 'with downstream tubes' do
    # create a multiplexing submission and it's requests
    let(:mx_submission) { create(:submission, state: 'completed') }

    let(:mx_request1) do
      create(:mx_request, state: state_completed, include_submissions: true, submission: mx_submission)
    end
    let(:mx_request2) do
      create(:mx_request, state: state_completed, include_submissions: true, submission: mx_submission)
    end

    # add multiplexing requests to requests_as_source of the current wells
    let(:current_well1) do
      create(
        :well_with_transfer_requests,
        aliquots: [current_aliquot1],
        location: 'A1',
        transfer_requests_as_source: [mx_request1],
        transfer_requests_as_target: [transfer_request1]
      )
    end
    let(:current_well2) do
      create(
        :well_with_transfer_requests,
        aliquots: [current_aliquot2],
        location: 'B1',
        transfer_requests_as_source: [mx_request2],
        transfer_requests_as_target: [transfer_request2]
      )
    end

    # create aliquots for the pool tube
    let(:pool_aliquot1) do
      create(
        :aliquot,
        sample: sample1,
        request: mx_request1,
        outer_request: mx_request1,
        study: submission_study,
        project: submission_project
      )
    end
    let(:pool_aliquot2) do
      create(
        :aliquot,
        sample: sample2,
        request: mx_request2,
        outer_request: mx_request2,
        study: submission_study,
        project: submission_project
      )
    end

    # create a pool tube
    let(:pool_tube_uuid) { 'pool-tube-uuid' }
    let(:pool_tube) do
      create(
        :tube,
        uuid: pool_tube_uuid,
        purpose_name: 'Pooled Tube Purpose',
        barcode_number: '3',
        purpose_uuid: 'pool-tube-purpose-uuid',
        state: 'passed',
        aliquots: [pool_aliquot1, pool_aliquot2]
      )
    end

    # transfer requests from each current well to the pool tube
    let(:pool_transfer_request1) do
      create(
        :transfer_request,
        source_asset: current_well1,
        target_asset: pool_tube,
        submission: mx_submission,
        state: state_completed
      )
    end
    let(:pool_transfer_request2) do
      create(
        :transfer_request,
        source_asset: current_well2,
        target_asset: pool_tube,
        submission: mx_submission,
        state: state_completed
      )
    end

    # create norm tube aliquots
    let(:norm_aliquot1) do
      create(
        :aliquot,
        sample: sample1,
        request: mx_request1,
        outer_request: mx_request1,
        study: submission_study,
        project: submission_project
      )
    end
    let(:norm_aliquot2) do
      create(
        :aliquot,
        sample: sample2,
        request: mx_request2,
        outer_request: mx_request2,
        study: submission_study,
        project: submission_project
      )
    end

    # transfer requests from each current well to the pool tube
    let(:current_well1_to_norm_transfer_request1) do
      create(
        :transfer_request,
        source_asset: current_well1,
        target_asset: nil, # norm_tube,
        submission: mx_submission,
        state: state_completed
      )
    end
    let(:current_well2_to_norm_transfer_request2) do
      create(
        :transfer_request,
        source_asset: current_well2,
        target_asset: nil, # norm_tube,
        submission: mx_submission,
        state: state_completed
      )
    end

    # create a sequencing submission and its requests
    let(:seq_submission) { create(:submission, state: state_cancelled) }

    let(:seq_request) do
      create(
        :ultima_sequencing_request,
        state: state_cancelled,
        include_submissions: true,
        submission_id: seq_submission.id
      )
    end

    # create a norm tube
    let(:norm_tube_uuid) { 'norm-tube-uuid' }
    let(:norm_tube) do
      create(
        :tube,
        uuid: norm_tube_uuid,
        purpose_name: 'Norm Tube Purpose',
        barcode_number: '4',
        purpose_uuid: 'norm-tube-purpose-uuid',
        state: 'passed',
        aliquots: [norm_aliquot1, norm_aliquot2],
        transfer_requests_as_source: [],
        transfer_requests_as_target: [current_well1_to_norm_transfer_request1, current_well2_to_norm_transfer_request2],
        requests_as_source: [seq_request]
      )
    end

    before do
      allow(labware).to receive(:descendants).and_return([pool_tube, norm_tube])

      allow(Sequencescape::Api::V2::Tube).to receive(:find_all).with(
        {
          uuid: norm_tube_uuid
        },
        { includes: DESCENDENT_TUBE_INCLUDES }
      ).and_return([norm_tube])
    end

    context 'with a labware that has only a cancelled sequencing submission' do
      it 'does not allow submissions yet' do
        expect(presenter.allow_new_submission?).to be false
      end

      it 'has no pending submissions' do
        expect(presenter.pending_submissions?).to be false
      end

      it 'displays the default sidebar' do
        expect(presenter.sidebar_partial).to eq('default')
      end
    end

    context 'with a labware that has a started sequencing submission' do
      let(:seq_submission) { create(:submission, state: state_started) }

      let(:seq_request) do
        create(
          :ultima_sequencing_request,
          state: state_started,
          include_submissions: true,
          submission_id: seq_submission.id
        )
      end

      it 'does allow submissions' do
        expect(presenter.allow_new_submission?).to be true
      end

      it 'has no pending submissions' do
        expect(presenter.pending_submissions?).to be false
      end

      it 'displays the submissions sidebar' do
        expect(presenter.sidebar_partial).to eq('submission_default')
      end
    end

    context 'with a labware that has only a completed sequencing submission' do
      let(:seq_submission) { create(:submission, state: state_completed) }

      let(:seq_request) do
        create(
          :ultima_sequencing_request,
          state: state_completed,
          include_submissions: true,
          submission_id: seq_submission.id
        )
      end

      it 'does allow submissions' do
        expect(presenter.allow_new_submission?).to be true
      end

      it 'has no pending submissions' do
        expect(presenter.pending_submissions?).to be false
      end

      it 'displays the submissions sidebar' do
        expect(presenter.sidebar_partial).to eq('submission_default')
      end
    end

    context 'with a labware that has both cancelled and completed sequencing submissions' do
      let(:seq_submission1) { create(:submission, state: state_cancelled) }
      let(:seq_submission2) { create(:submission, state: state_completed) }

      let(:seq_request1) do
        create(
          :ultima_sequencing_request,
          state: state_cancelled,
          include_submissions: true,
          submission_id: seq_submission.id
        )
      end

      let(:seq_request2) do
        create(
          :ultima_sequencing_request,
          state: state_completed,
          include_submissions: true,
          submission_id: seq_submission.id
        )
      end

      let(:norm_tube) do
        create(
          :tube,
          uuid: norm_tube_uuid,
          purpose_name: 'Norm Tube Purpose',
          barcode_number: '4',
          purpose_uuid: 'norm-tube-purpose-uuid',
          state: 'passed',
          aliquots: [norm_aliquot1, norm_aliquot2],
          transfer_requests_as_source: [],
          transfer_requests_as_target: [current_well1_to_norm_transfer_request1,
                                        current_well2_to_norm_transfer_request2],
          requests_as_source: [seq_request1, seq_request2]
        )
      end

      it 'does allow submissions' do
        expect(presenter.allow_new_submission?).to be true
      end

      it 'has no pending submissions' do
        expect(presenter.pending_submissions?).to be false
      end

      it 'displays the submissions sidebar' do
        expect(presenter.sidebar_partial).to eq('submission_default')
      end
    end
  end

  # with an already active submission we hide the submission sidebar again
  context 'when a submission has been created we no longer display the submission sidebar' do
    let(:pending_submission) { create(:submission, state: state_pending) }

    let(:pending_request1) do
      create(
        :ultima_sequencing_request,
        state: state_pending,
        include_submissions: true,
        submission_id: pending_submission.id
      )
    end
    let(:pending_request2) do
      create(
        :ultima_sequencing_request,
        state: state_pending,
        include_submissions: true,
        submission_id: pending_submission.id
      )
    end

    let(:current_well1) do
      create(
        :well_with_transfer_requests,
        aliquots: [current_aliquot1],
        location: 'A1',
        transfer_requests_as_source: [],
        transfer_requests_as_target: [transfer_request1],
        requests_as_source: [pending_request1]
      )
    end
    let(:current_well2) do
      create(
        :well_with_transfer_requests,
        aliquots: [current_aliquot2],
        location: 'B1',
        transfer_requests_as_source: [],
        transfer_requests_as_target: [transfer_request2],
        requests_as_source: [pending_request2]
      )
    end

    let(:labware) do
      create :plate,
             uuid: current_plate_uuid,
             purpose_name: current_plate_purpose_name,
             purpose_uuid: current_plate_purpose_uuid,
             wells: current_wells,
             ancestors: [ancestor_plate],
             barcode_number: '2',
             state: 'passed',
             direct_submissions: [pending_submission]
    end

    it 'has pending submissions' do
      expect(presenter.send(:pending_submissions?)).to be true
    end

    it 'does not allow submissions' do
      expect(presenter.allow_new_submission?).to be false
    end

    it 'displays the default sidebar' do
      expect(presenter.sidebar_partial).to eq('default')
    end
  end
end
