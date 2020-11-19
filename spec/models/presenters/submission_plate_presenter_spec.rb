# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::SubmissionPlatePresenter do
  has_a_working_api

  subject(:presenter) do
    described_class.new(
      api: api,
      labware: labware
    )
  end

  let(:submission_options) do
    {
      'LTHR-96' => { template_name: 'example', request_options: { option: 1 } },
      'LTHR-384' => { template_name: 'example2', request_options: { option: 2 } }
    }
  end

  let(:example_template_uuid) { SecureRandom.uuid }
  let(:example2_template_uuid) { SecureRandom.uuid }

  before do
    create(:purpose_config, uuid: labware.purpose.uuid, submission_options: submission_options)
    Settings.submission_templates = {
      'example' => example_template_uuid,
      'example2' => example2_template_uuid
    }
  end

  context 'without submissions' do
    it_behaves_like 'a labware presenter'
    it_behaves_like 'a stock presenter'

    let(:labware) { create :v2_plate_for_submission, purpose_name: purpose_name, barcode_number: 2 }
    let(:barcode_string) { 'DN2T' }
    let(:purpose_name) { 'Test Plate' }
    let(:title) { purpose_name }
    let(:state) { 'pending' }
    let(:sidebar_partial) { 'submission' }
    let(:summary_tab) do
      [
        %w[Barcode DN2T],
        ['Number of wells', '96/96'],
        ['Plate type', purpose_name],
        ['Current plate state', state],
        ['Input plate barcode', barcode_string],
        ['Created on', '2017-06-29']
      ]
    end

    let(:template_options) do
      [
        ['LTHR-96', be_a_kind_of(SequencescapeSubmission).and(
          have_attributes(
            template_uuid: example_template_uuid,
            request_options: { 'option' => 1 },
            asset_groups: [labware.wells.map(&:uuid)]
          )
        )],
        ['LTHR-384', be_a_kind_of(SequencescapeSubmission).and(
          have_attributes(
            template_uuid: example2_template_uuid,
            request_options: { 'option' => 2 },
            asset_groups: [labware.wells.map(&:uuid)]
          )
        )]
      ]
    end

    it 'renders the submission options' do
      expect { |b| presenter.each_submission_option(&b) }.to yield_successive_args(*template_options)
    end
  end

  context 'with submissions' do
    # Once we have submissions, we're essentially just a normal stock plate

    it_behaves_like 'a labware presenter'
    it_behaves_like 'a stock presenter'

    let(:labware) { create :v2_stock_plate, purpose_name: purpose_name, barcode_number: 2, pool_sizes: [2] }
    let(:barcode_string) { 'DN2T' }
    let(:purpose_name) { 'Test Plate' }
    let(:title) { purpose_name }
    let(:state) { 'passed' }
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
  end
end
