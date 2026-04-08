# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/lcmb_pcr_xp_concentrations_for_custom_pooling.csv.erb' do
  let(:qc_result_options_1) { { value: 1.5, key: 'concentration', units: 'ng/ul' } }
  let(:qc_result_options_2) { { value: 2.7, key: 'concentration', units: 'ng/ul' } }

  let(:well_a1) do
    create(:well, position: { 'name' => 'A1' }, qc_results: create_list(:qc_result, 1, qc_result_options_1))
  end
  let(:well_b1) do
    create(:well, position: { 'name' => 'B1' }, qc_results: create_list(:qc_result, 1, qc_result_options_2))
  end

  let(:ancestor_well_a1) { create(:well, position: { 'name' => 'A1' }) }
  let(:ancestor_well_b1) { create(:well, position: { 'name' => 'B1' }) }
  let(:labware) { create(:plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }
  let(:ancestor_labware) { create(:plate, wells: [ancestor_well_a1, ancestor_well_b1], pool_sizes: [1, 1]) }

  let(:well_a1_sanger_sample_id) { well_a1.aliquots.first.sample.sanger_sample_id }
  let(:well_b1_sanger_sample_id) { well_b1.aliquots.first.sample.sanger_sample_id }

  let(:well_a1_sample_name) { well_a1.aliquots.first.sample.name }
  let(:well_b1_sample_name) { well_b1.aliquots.first.sample.name }

  let(:ancestor_barcode) { ancestor_labware.human_barcode }

  # the ancestor plate we set up is not connected as a true ancestor of our plate,
  # the exports controller would determine the true ancestor, here we just assign
  # a plate to simulate that for the test
  before do
    assign(:plate, labware)
    assign(:ancestor_plate, ancestor_labware)
  end

  let(:expected_content) do
    [
      ['Source Barcode', 'Sample Name', 'Well', 'Concentration (ng/ul)', 'Sequencescape Sample ID', 'Shotgun?', 'ISC?'],
      [ancestor_barcode, well_a1_sample_name, 'A1', '1.5', well_a1_sanger_sample_id, nil, nil],
      [ancestor_barcode, well_b1_sample_name, 'B1', '2.7', well_b1_sanger_sample_id, nil, nil]
    ]
  end

  it 'renders the expected content' do
    expect(CSV.parse(render)).to eq(expected_content)
  end
end
