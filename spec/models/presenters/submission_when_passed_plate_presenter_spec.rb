# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::SubmissionWhenPassedPlatePresenter do
  subject(:presenter) { described_class.new(labware:) }

  let(:submission_options) do
    {
      'TEST-96' => {
        template_name: 'example',
        request_options: {
          option: 1
        }
      },
      'TEST-384' => {
        template_name: 'example2',
        request_options: {
          option: 2
        }
      }
    }
  end

  let(:example_template_uuid) { SecureRandom.uuid }
  let(:example2_template_uuid) { SecureRandom.uuid }

  before do
    create(:purpose_config, uuid: labware.purpose.uuid, submission_options: submission_options)
    Settings.submission_templates = { 'example' => example_template_uuid, 'example2' => example2_template_uuid }
  end

  let(:wells_with_aliquots) { %w[2-well-A1 2-well-B1] }

  let(:template_options) do
    [
      [
        'TEST-96',
        be_a(SequencescapeSubmission).and(
          have_attributes(
            template_uuid: example_template_uuid,
            request_options: {
              'option' => 1
            },
            asset_groups: [{ asset_uuids: wells_with_aliquots, autodetect_studies: true, autodetect_projects: true }]
          )
        )
      ],
      [
        'TEST-384',
        be_a(SequencescapeSubmission).and(
          have_attributes(
            template_uuid: example2_template_uuid,
            request_options: {
              'option' => 2
            },
            asset_groups: [{ asset_uuids: wells_with_aliquots, autodetect_studies: true, autodetect_projects: true }]
          )
        )
      ]
    ]
  end

  context 'without submissions' do
    it_behaves_like 'a labware presenter'

    let(:labware) do
      create :plate_for_submission,
             purpose_name: purpose_name,
             barcode_number: 2,
             direct_submissions: [],
             study: submission_study,
             project: submission_project
    end

    let(:barcode_string) { 'DN2T' }
    let(:purpose_name) { 'Test Plate' }
    let(:title) { purpose_name }
    let(:state) { 'pending' }
    let(:sidebar_partial) { 'default' }
    let(:submission_study) { create :study, name: 'Submission Study' }
    let(:submission_project) { create :project, name: 'Submission Project' }
    let(:summary_tab) do
      [
        %w[Barcode DN2T],
        ['Number of wells', '2/96'],
        ['Plate type', purpose_name],
        ['Current plate state', state],
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

    it 'renders the submission options' do
      expect { |b| presenter.each_submission_option(&b) }.to yield_successive_args(*template_options)
    end

    it 'has no pending submissions' do
      expect(presenter.pending_submissions?).to be false
    end
  end

  context 'with pending submissions' do
    it_behaves_like 'a labware presenter'

    let(:labware) do
      create :plate_for_submission, purpose_name: purpose_name, barcode_number: 2, direct_submissions: submissions
    end

    let(:submissions) { create_list :submission, 1, state: 'pending' }
    let(:barcode_string) { 'DN2T' }
    let(:purpose_name) { 'Test Plate' }
    let(:title) { purpose_name }
    let(:state) { 'pending' }
    let(:sidebar_partial) { 'default' }
    let(:summary_tab) do
      [
        %w[Barcode DN2T],
        ['Number of wells', '2/96'],
        ['Plate type', purpose_name],
        ['Current plate state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end

    it 'has pending submissions' do
      expect(presenter.pending_submissions?).to be true
    end
  end

  context 'with a race condition' do
    # We fetch the order list *after* we've fetched the plate and wells, to avoid
    # the need to pull it back every single time.
    # In some cases, the order can finish processing between us fetching the wells,
    # and fetching the orders. If this happens we don't want to show the create-submission
    # buttons. However, we don't want other submissions to block the appearance of the buttons.
    # So we use timestamps!
    before { travel_to now }

    it_behaves_like 'a labware presenter'

    let(:labware) do
      create :plate_for_submission, purpose_name: purpose_name, barcode_number: 2, direct_submissions: submissions
    end
    let(:now) { Time.zone.parse('2020-11-24 16:13:43 +0000') }
    let(:submissions) { create_list :submission, 1, state: 'ready', updated_at: now - 5.seconds }
    let(:barcode_string) { 'DN2T' }
    let(:purpose_name) { 'Test Plate' }
    let(:title) { purpose_name }
    let(:state) { 'pending' }
    let(:sidebar_partial) { 'default' }
    let(:summary_tab) do
      [
        %w[Barcode DN2T],
        ['Number of wells', '2/96'],
        ['Plate type', purpose_name],
        ['Current plate state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end

    it 'has pending submissions' do
      expect(presenter.pending_submissions?).to be true
    end
  end

  context 'with built submissions' do
    # Once we have submissions, we're essentially just a normal plate

    it_behaves_like 'a labware presenter'

    let(:labware) { create :stock_plate, purpose_name: purpose_name, barcode_number: 2, pool_sizes: [2] }
    let(:barcode_string) { 'DN2T' }
    let(:purpose_name) { 'Test Plate' }
    let(:title) { purpose_name }
    let(:state) { 'passed' }
    let(:sidebar_partial) { 'submission_default' }
    let(:summary_tab) do
      [
        %w[Barcode DN2T],
        ['Number of wells', '2/96'],
        ['Plate type', purpose_name],
        ['Current plate state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end
  end

  context 'with cancelled submissions' do
    # If our requests have been cancelled, then we're back at square 1

    it_behaves_like 'a labware presenter'

    let(:labware) do
      create :stock_plate,
             purpose_name: purpose_name,
             barcode_number: 2,
             pool_sizes: [2],
             direct_submissions: submissions,
             state: state
    end
    let(:submissions) { create_list :submission, 1, state: }
    let(:barcode_string) { 'DN2T' }
    let(:purpose_name) { 'Test Plate' }
    let(:title) { purpose_name }
    let(:state) { 'cancelled' }
    let(:sidebar_partial) { 'default' }
    let(:summary_tab) do
      [
        %w[Barcode DN2T],
        ['Number of wells', '2/96'],
        ['Plate type', purpose_name],
        ['Current plate state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end

    it 'renders the submission options' do
      expect { |b| presenter.each_submission_option(&b) }.to yield_successive_args(*template_options)
    end

    it 'has no pending submissions' do
      # We have submissions, but they are built. pending_submissions? controls aspects like the
      # refresh, that would be a nightmare if you were trying to set up a submission
      expect(presenter.pending_submissions?).to be false
    end
  end

  context 'with failed submissions' do
    # If our requests have been failed, then we're back at square 1

    it_behaves_like 'a labware presenter'

    let(:labware) do
      create :stock_plate,
             purpose_name: purpose_name,
             barcode_number: 2,
             pool_sizes: [2],
             direct_submissions: submissions,
             state: state
    end
    let(:submissions) { create_list :submission, 1, state: }
    let(:barcode_string) { 'DN2T' }
    let(:purpose_name) { 'Test Plate' }
    let(:title) { purpose_name }
    let(:state) { 'failed' }
    let(:sidebar_partial) { 'default' }
    let(:summary_tab) do
      [
        %w[Barcode DN2T],
        ['Number of wells', '2/96'],
        ['Plate type', purpose_name],
        ['Current plate state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end

    it 'renders the submission options' do
      expect { |b| presenter.each_submission_option(&b) }.to yield_successive_args(*template_options)
    end

    it 'has no pending submissions' do
      # We have submissions, but they are built. pending_submissions? controls aspects like the
      # refresh, that would be a nightmare if you were trying to set up a submission
      expect(presenter.pending_submissions?).to be false
    end
  end

  describe '#asset_groups' do
    subject(:asset_groups) { presenter.send(:asset_groups) }

    let(:labware) { create(:plate_empty) }

    # This example is when a well is failed (aliquot.request failed) before a submission is made
    context 'when the aliquot request is failed' do
      let(:aliquot1) { create(:aliquot, request: create(:request, state: 'passed')) }
      let(:aliquot2) { create(:aliquot, request: create(:request, state: 'failed')) }
      let(:aliquot3) { create(:aliquot, request: create(:request, state: 'passed')) }
      let(:well1) { create(:well, uuid: 'uuid1', order_group: 'group1', aliquots: [aliquot1]) }
      let(:well2) { create(:well, uuid: 'uuid2', order_group: 'group1', aliquots: [aliquot2]) }
      let(:well3) { create(:well, uuid: 'uuid3', order_group: 'group2', aliquots: [aliquot3]) }

      before do
        allow(labware).to receive(:wells).and_return([well1, well2, well3])
        allow(well1).to receive(:requests_as_source).and_return(nil)
        allow(well2).to receive(:requests_as_source).and_return(nil)
        allow(well3).to receive(:requests_as_source).and_return(nil)
      end

      it 'filters out wells with failed aliquot requests' do
        expect(asset_groups).to eq(
          [
            { assets: %w[uuid1], autodetect_studies: true, autodetect_projects: true },
            { assets: %w[uuid3], autodetect_studies: true, autodetect_projects: true }
          ]
        )
      end
    end
  end
end
