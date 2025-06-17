# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/targeted_nanoseq_al_lib_concentrations_for_customer.csv.erb' do
  let(:qc_result_options) { { value: 1.5, key: 'molarity', units: 'nM' } }

  let(:well_a1) do
    create(:v2_well, position: { 'name' => 'A1' }, qc_results: create_list(:qc_result, 1, qc_result_options))
  end
  let(:well_b1) do
    create(:v2_well, position: { 'name' => 'B1' }, qc_results: create_list(:qc_result, 1, qc_result_options))
  end
  let(:labware) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

  before { assign(:plate, labware) }

  let(:well_a1_sanger_sample_id) { well_a1.aliquots.first.sample.sanger_sample_id }
  let(:well_b1_sanger_sample_id) { well_b1.aliquots.first.sample.sanger_sample_id }
  let(:well_a1_supplier_name) { well_a1.aliquots.first.sample.sample_metadata.supplier_name }
  let(:well_b1_supplier_name) { well_b1.aliquots.first.sample.sample_metadata.supplier_name }

  let(:expected_content) do
    [
      ['Plate Barcode', labware.barcode.human],
      [],
      [
        'Well',
        'Concentration (nM)',
        'Sanger Sample Id',
        'Supplier Sample Name',
        'Input amount available (fmol)',
        'Input amount desired',
        'Sample volume',
        'Diluent volume',
        'Hyb Panel'
      ],
      ['A1', '1.5', well_a1_sanger_sample_id, well_a1_supplier_name, (1.5 * 25).to_s, nil, nil, nil, nil],
      ['B1', '1.5', well_b1_sanger_sample_id, well_b1_supplier_name, (1.5 * 25).to_s, nil, nil, nil, nil]
    ]
  end

  it 'renders the expected content' do
    expect(CSV.parse(render)).to eq(expected_content)
  end
end
