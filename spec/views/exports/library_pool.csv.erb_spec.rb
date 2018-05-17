# frozen_string_literal: true

require 'spec_helper'

describe 'exports/library_pool.csv.erb' do
  context 'with a full plate' do
    has_a_working_api

    let(:well_a1) { create(:well_v2, position: 'A1', qc_results: create_list(:qc_result, 1)) }
    let(:well_b1) { create(:well_v2, position: 'B1', qc_results: create_list(:qc_result, 1)) }
    let(:labware) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

    before do
      assign(:plate, labware)
    end

    let(:expected_content) do
      [
        ['Plate Barcode', 'DN1S'],
        [],
        %w[Well Concentration Pick Pool],
        %w[A1 1 1 1],
        %w[B1 1 1 2]
      ]
    end

    it 'renders the expected content' do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end
end
