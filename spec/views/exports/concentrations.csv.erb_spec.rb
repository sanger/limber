# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/concentrations.csv.erb' do
  context 'with a full plate' do
    has_a_working_api

    let(:well_a1) { create(:v2_well, position: { 'name' => 'A1' }, qc_results: create_list(:qc_result, 1)) }
    let(:well_b1) { create(:v2_well, position: { 'name' => 'B1' }, qc_results: create_list(:qc_result, 1)) }
    let(:labware) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

    before do
      assign(:plate, labware)
    end

    let(:expected_content) do
      [
        ['Plate Barcode', 'DN1S'],
        [],
        %w[Well Concentration Pick Pool],
        %w[A1 1.5 1 1],
        %w[B1 1.5 1 2]
      ]
    end

    it 'renders the expected content' do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end
end
