# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::SubmissionTubePresenter do
  subject(:presenter) { described_class.new(labware:) }

  let(:submission_options) do
    {
      'Additional Sequencing 1' => {
        template_name: 'Additional Sequencing 1',
        request_options: {
          option: 1
        }
      },
      'Additional Sequencing 2' => {
        template_name: 'Additional Sequencing 2',
        request_options: {
          option: 2
        }
      }
    }
  end

  let(:as_template_uuid) { SecureRandom.uuid }
  let(:as2_template_uuid) { SecureRandom.uuid }

  before do
    create(:purpose_config, uuid: labware.purpose.uuid, submission_options: submission_options)
    Settings.submission_templates = { 'Additional Sequencing 1' => as_template_uuid,
                                      'Additional Sequencing 2' => as2_template_uuid }
  end

  let(:template_options) do
    [
      [
        'Additional Sequencing 1',
        be_a(SequencescapeSubmission).and(
          have_attributes(
            template_uuid: as_template_uuid,
            request_options: {
              'option' => 1
            },
            asset_groups: [{ asset_uuids: [labware.uuid], autodetect_studies: true, autodetect_projects: true }]
          )
        )
      ],
      [
        'Additional Sequencing 2',
        be_a(SequencescapeSubmission).and(
          have_attributes(
            template_uuid: as2_template_uuid,
            request_options: {
              'option' => 2
            },
            asset_groups: [{ asset_uuids: [labware.uuid], autodetect_studies: true, autodetect_projects: true }]
          )
        )
      ]
    ]
  end

  context 'without submissions' do
    it_behaves_like 'a labware presenter'
    it_behaves_like 'a stock presenter'

    let(:labware) do
      create :v2_tube,
             purpose_name: purpose_name,
             direct_submissions: [],
             study: submission_study,
             project: submission_project
    end

    let(:barcode_summary) { "#{labware.human_barcode} <em>#{labware.labware_barcode.machine}</em>" }
    let(:barcode_string) { 'Unknown' }
    let(:purpose_name) { 'Test Tube' }
    let(:title) { purpose_name }
    let(:state) { 'passed' }
    let(:sidebar_partial) { 'submission_default' }
    let(:submission_study) { create :v2_study, name: 'Submission Study' }
    let(:submission_project) { create :v2_project, name: 'Submission Project' }
    let(:summary_tab) do
      [
        ['Barcode', barcode_summary],
        ['Tube type', purpose_name],
        ['Current tube state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
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
    it_behaves_like 'a stock presenter'

    let(:labware) do
      create :v2_tube, purpose_name: purpose_name, direct_submissions: submissions
    end

    let(:submissions) { create_list :v2_submission, 1, state: 'pending' }
    let(:barcode_summary) { "#{labware.human_barcode} <em>#{labware.labware_barcode.machine}</em>" }
    let(:barcode_string) { 'Unknown' }
    let(:purpose_name) { 'Test Tube' }
    let(:title) { purpose_name }
    let(:state) { 'passed' }
    let(:sidebar_partial) { 'submission_default' }
    let(:summary_tab) do
      [
        ['Barcode', barcode_summary],
        ['Tube type', purpose_name],
        ['Current tube state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end

    it 'has pending submissions' do
      expect(presenter.pending_submissions?).to be true
    end
  end

  context 'with a race condition' do
    # We fetch the order list *after* we've fetched the tube, to avoid
    # the need to pull it back every single time.
    # In some cases, the order can finish processing between us fetching the tube,
    # and fetching the orders. If this happens we don't want to show the create-submission
    # buttons. However, we don't want other submissions to block the appearance of the buttons.
    # So we use timestamps!
    before { travel_to now }

    it_behaves_like 'a labware presenter'
    it_behaves_like 'a stock presenter'

    let(:labware) do
      create :v2_tube, purpose_name: purpose_name, direct_submissions: submissions
    end
    let(:now) { Time.zone.parse('2020-11-24 16:13:43 +0000') }
    let(:submissions) { create_list :v2_submission, 1, state: 'ready', updated_at: now - 5.seconds }
    let(:barcode_summary) { "#{labware.human_barcode} <em>#{labware.labware_barcode.machine}</em>" }
    let(:barcode_string) { 'Unknown' }
    let(:purpose_name) { 'Test Tube' }
    let(:title) { purpose_name }
    let(:state) { 'passed' }
    let(:sidebar_partial) { 'submission_default' }
    let(:summary_tab) do
      [
        ['Barcode', barcode_summary],
        ['Tube type', purpose_name],
        ['Current tube state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end

    it 'has pending submissions' do
      expect(presenter.pending_submissions?).to be true
    end
  end

  context 'with built submissions' do
    it_behaves_like 'a labware presenter'
    it_behaves_like 'a stock presenter'

    let(:labware) { create :v2_tube, purpose_name: purpose_name, direct_submissions: submissions }
    let(:submissions) { create_list :v2_submission, 1, state: 'ready' }
    let(:barcode_summary) { "#{labware.human_barcode} <em>#{labware.labware_barcode.machine}</em>" }
    let(:barcode_string) { 'Unknown' }
    let(:purpose_name) { 'Test Tube' }
    let(:title) { purpose_name }
    let(:state) { 'passed' }
    let(:sidebar_partial) { 'submission_default' }
    let(:summary_tab) do
      [
        ['Barcode', barcode_summary],
        ['Tube type', purpose_name],
        ['Current tube state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end
  end

  context 'with cancelled submissions' do
    # If our requests have been cancelled, then we're back at square 1

    it_behaves_like 'a labware presenter'
    it_behaves_like 'a stock presenter'

    let(:labware) do
      create :v2_tube,
             purpose_name: purpose_name,
             direct_submissions: submissions,
             state: state
    end
    let(:submissions) { create_list :v2_submission, 1, state: 'cancelled' }
    let(:barcode_summary) { "#{labware.human_barcode} <em>#{labware.labware_barcode.machine}</em>" }
    let(:barcode_string) { 'Unknown' }
    let(:purpose_name) { 'Test Tube' }
    let(:title) { purpose_name }
    let(:state) { 'passed' }
    let(:sidebar_partial) { 'submission_default' }
    let(:summary_tab) do
      [
        ['Barcode', barcode_summary],
        ['Tube type', purpose_name],
        ['Current tube state', state],
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
    it_behaves_like 'a stock presenter'

    let(:labware) do
      create :v2_tube,
             purpose_name: purpose_name,
             direct_submissions: submissions,
             state: state
    end
    let(:submissions) { create_list :v2_submission, 1, state: 'failed' }
    let(:barcode_summary) { "#{labware.human_barcode} <em>#{labware.labware_barcode.machine}</em>" }
    let(:barcode_string) { 'Unknown' }
    let(:purpose_name) { 'Test Tube' }
    let(:title) { purpose_name }
    let(:state) { 'passed' }
    let(:sidebar_partial) { 'submission_default' }
    let(:summary_tab) do
      [
        ['Barcode', barcode_summary],
        ['Tube type', purpose_name],
        ['Current tube state', state],
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

  context 'with a failed tube' do
    it_behaves_like 'a labware presenter'
    it_behaves_like 'a stock presenter'

    let(:labware) { create :v2_tube, purpose_name: purpose_name, direct_submissions: submissions, state: state }
    let(:submissions) { create_list :v2_submission, 1, state: 'ready' }
    let(:barcode_summary) { "#{labware.human_barcode} <em>#{labware.labware_barcode.machine}</em>" }
    let(:barcode_string) { 'Unknown' }
    let(:purpose_name) { 'Test Tube' }
    let(:title) { purpose_name }
    let(:state) { 'failed' }
    let(:sidebar_partial) { 'default' }
    let(:summary_tab) do
      [
        ['Barcode', barcode_summary],
        ['Tube type', purpose_name],
        ['Current tube state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end
  end
end
