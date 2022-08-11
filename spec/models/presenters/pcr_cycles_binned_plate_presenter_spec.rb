# frozen_string_literal: true

require 'rails_helper'
require 'presenters/pcr_cycles_binned_plate_presenter'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::PcrCyclesBinnedPlatePresenter do
  has_a_working_api

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
      ['PCR Cycles', '16, 14, and 12'],
      ['Created on', '2019-06-10']
    ]
  end
  let(:sidebar_partial) { 'default' }

  let(:request_a1) { create :dilution_and_cleanup_request, state: 'started', uuid: 'request-1', pcr_cycles: 16 }
  let(:request_a2) { create :dilution_and_cleanup_request, state: 'started', uuid: 'request-2', pcr_cycles: 14 }
  let(:request_b2) { create :dilution_and_cleanup_request, state: 'started', uuid: 'request-3', pcr_cycles: 14 }
  let(:request_a3) { create :dilution_and_cleanup_request, state: 'started', uuid: 'request-4', pcr_cycles: 12 }

  # Create binning for 4 wells in 3 bins:
  #     1   2   3
  # A   *   *   *
  # B       *
  let(:well_a1) do
    create(
      :v2_well,
      position: {
        'name' => 'A1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: '0.6'),
      outer_request: request_a1
    )
  end
  let(:well_a2) do
    create(
      :v2_well,
      position: {
        'name' => 'A2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: '10.0'),
      outer_request: request_a2
    )
  end
  let(:well_b2) do
    create(
      :v2_well,
      position: {
        'name' => 'B2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: '12.0'),
      outer_request: request_b2
    )
  end
  let(:well_a3) do
    create(
      :v2_well,
      position: {
        'name' => 'A3'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: '20.0'),
      outer_request: request_a3
    )
  end

  let(:labware) do
    build :v2_plate,
          purpose_name: purpose_name,
          state: state,
          barcode_number: 1,
          pool_sizes: [],
          wells: [well_a1, well_a2, well_b2, well_a3],
          created_at: '2019-06-10 12:00:00 +0100'
  end

  let(:warnings) { {} }
  let(:label_class) { 'Labels::PlateLabel' }

  before do
    stub_v2_plate(
      labware,
      stub_search: false,
      custom_includes: 'wells.aliquots,wells.qc_results,wells.aliquots.request'
    )
  end

  subject(:presenter) { Presenters::PcrCyclesBinnedPlatePresenter.new(api: api, labware: labware) }

  context 'when binning' do
    it_behaves_like 'a labware presenter'

    context 'pcr cycles binned plate display' do
      it 'should create a key for the bins that will be displayed' do
        # NB. contains min/max because just using bins template, but fields not needed in presentation
        expected_bins_key = [
          { 'colour' => 1, 'pcr_cycles' => 16 },
          { 'colour' => 2, 'pcr_cycles' => 14 },
          { 'colour' => 3, 'pcr_cycles' => 12 }
        ]

        expect(presenter.bins_key).to eq(expected_bins_key)
      end

      it 'should create bin details which will be used to colour and annotate the well aliquots' do
        expected_bin_details = {
          'A1' => {
            'colour' => 1,
            'pcr_cycles' => 16
          },
          'A2' => {
            'colour' => 2,
            'pcr_cycles' => 14
          },
          'A3' => {
            'colour' => 3,
            'pcr_cycles' => 12
          },
          'B2' => {
            'colour' => 2,
            'pcr_cycles' => 14
          }
        }

        expect(presenter.bin_details).to eq(expected_bin_details)
      end
    end
  end
end
