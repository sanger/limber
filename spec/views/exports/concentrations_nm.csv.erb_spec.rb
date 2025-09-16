# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/concentrations_nm.csv.erb' do
  context 'with a full plate' do
    has_a_working_api

    let(:qc_result_options) { { value: 1.5, key: 'molarity', units: 'nM' } }

    let(:well_a1) do
      create(:v2_well, position: { 'name' => 'A1' }, qc_results: create_list(:qc_result, 1, qc_result_options))
    end
    let(:well_b1) do
      create(:v2_well, position: { 'name' => 'B1' }, qc_results: create_list(:qc_result, 1, qc_result_options))
    end
    let(:labware) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

    before { assign(:plate, labware) }

    let(:expected_content) do
      [['Plate Barcode', labware.barcode.human], [], %w[Well Concentration Pick Pool], %w[A1 1.5 1 1], %w[B1 1.5 1 2]]
    end

    it 'renders the expected content' do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end

  context 'when a plate is a branch point' do
    # Test branching of the same wells on a plate with multiple submissions.
    # We want to ensure that each well appears only once in the CSV output,
    # because they do not represent pooling of wells, just multiple submissions.

    let(:qc_result_options) { { value: 1.5, key: 'molarity', units: 'nM' } }

    let(:well_a1) do
      create(:v2_well, position: { 'name' => 'A1' }, qc_results: create_list(:qc_result, 1, qc_result_options))
    end
    let(:well_b1) do
      create(:v2_well, position: { 'name' => 'B1' }, qc_results: create_list(:qc_result, 1, qc_result_options))
    end
    let(:labware) { create(:v2_plate, wells: [well_a1, well_b1]) }

    before do
      assign(:plate, labware)
      allow(well_a1).to receive(:submission_ids).and_return([1, 2])
      allow(well_b1).to receive(:submission_ids).and_return([1, 2])
    end

    let(:expected_content) do
      [['Plate Barcode', labware.barcode.human], [], %w[Well Concentration Pick Pool], %w[A1 1.5 1 1], %w[B1 1.5 1 1]]
    end

    it 'renders the expected content' do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end
end
