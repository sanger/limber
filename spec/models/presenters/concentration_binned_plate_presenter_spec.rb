# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::ConcentrationBinnedPlatePresenter do
  subject(:presenter) { described_class.new(labware:) }

  let(:purpose_name) { 'Limber example purpose' }
  let(:title) { purpose_name }
  let(:state) { 'pending' }
  let(:summary_tab) do
    [
      %w[Barcode DN1S],
      ['Number of wells', '4/96'],
      ['Plate type', purpose_name],
      ['Current plate state', state],
      ['Input plate barcode', 'DN2T'],
      ['PCR Cycles', '10'],
      ['Created on', '2019-06-10']
    ]
  end
  let(:sidebar_partial) { 'default' }

  # Create binning for 4 wells in 3 bins:
  #     1   2   3
  # A   *   *   *
  # B       *
  let(:well_a1) do
    create(:well, position: { 'name' => 'A1' }, qc_results: create_list(:qc_result_concentration, 1, value: '0.6'))
  end
  let(:well_a2) do
    create(:well, position: { 'name' => 'A2' }, qc_results: create_list(:qc_result_concentration, 1, value: '10.0'))
  end
  let(:well_b2) do
    create(:well, position: { 'name' => 'B2' }, qc_results: create_list(:qc_result_concentration, 1, value: '12.0'))
  end
  let(:well_a3) do
    create(:well, position: { 'name' => 'A3' }, qc_results: create_list(:qc_result_concentration, 1, value: '20.0'))
  end

  let(:labware) do
    build :plate,
          purpose_name: purpose_name,
          state: state,
          barcode_number: 1,
          pool_sizes: [],
          wells: [well_a1, well_a2, well_b2, well_a3],
          outer_requests: requests,
          created_at: '2019-06-10 12:00:00 +0100'
  end

  let(:requests) { Array.new(4) { |i| create :library_request, state: 'started', uuid: "request-#{i}" } }

  let(:warnings) { {} }
  let(:label_class) { 'Labels::PlateLabel' }

  before { stub_plate(labware, stub_search: false, custom_includes: 'wells.aliquots,wells.qc_results') }

  context 'when binning configuration is missing' do
    it 'throws an exception' do
      expect { presenter.binning_config }.to raise_error(Exception)
    end
  end

  context 'when binning configuration is present' do
    before do
      create(
        :concentration_binning_purpose_config,
        uuid: labware.purpose.uuid,
        warnings: warnings,
        label_class: label_class
      )
    end

    it_behaves_like 'a labware presenter'

    context 'concentration binned plate display' do
      it 'creates a key for the bins that will be displayed' do
        # NB. contains min/max because just using bins template, but fields not needed in presentation
        expected_bins_key = [
          { 'colour' => 1, 'max' => 25.0, 'min' => 0.0, 'pcr_cycles' => 16 },
          { 'colour' => 2, 'max' => 500.0, 'min' => 25.0, 'pcr_cycles' => 12 },
          { 'colour' => 3, 'max' => Float::INFINITY, 'min' => 500.0, 'pcr_cycles' => 8 }
        ]

        expect(presenter.bins_key).to eq(expected_bins_key)
      end

      it 'creates bin details which will be used to colour and annotate the well aliquots' do
        expected_bin_details = {
          'A1' => {
            'colour' => 1,
            'pcr_cycles' => 16
          },
          'A2' => {
            'colour' => 2,
            'pcr_cycles' => 12
          },
          'A3' => {
            'colour' => 3,
            'pcr_cycles' => 8
          },
          'B2' => {
            'colour' => 2,
            'pcr_cycles' => 12
          }
        }

        expect(presenter.bin_details).to eq(expected_bin_details)
      end
    end
  end
end
