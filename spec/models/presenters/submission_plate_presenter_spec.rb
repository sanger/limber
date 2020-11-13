# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::SubmissionPlatePresenter do
  has_a_working_api

  subject do
    described_class.new(
      api: api,
      labware: labware
    )
  end

  context 'without submissions' do
    it_behaves_like 'a labware presenter'
    it_behaves_like 'a stock presenter'

    let(:labware) { create :v2_plate_for_submission, purpose_name: purpose_name, barcode_number: 2 }
    let(:barcode_string) { 'DN2T' }
    let(:purpose_name) { 'Test Plate' }
    let(:title) { purpose_name }
    let(:state) { 'pending' }
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
  end
end
