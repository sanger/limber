# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/duplex_seq_pcr_xp_concentrations_for_custom_pooling.csv.erb' do
  let(:qc_result_options) { { value: 1.5, key: 'concentration', units: 'ng/ul' } }

  let(:well_a1) do
    create(:v2_well, position: { 'name' => 'A1' }, qc_results: create_list(:qc_result, 1, qc_result_options))
  end
  let(:well_b1) do
    create(:v2_well, position: { 'name' => 'B1' }, qc_results: create_list(:qc_result, 1, qc_result_options))
  end

  let(:ancestor_well_a1) do
    create(
      :v2_well,
      position: {
        'name' => 'A1'
      },
      qc_results: create_list(:qc_result, 1, qc_result_options),
      submit_for_sequencing: true,
      sub_pool: 1,
      coverage: 15
    )
  end
  let(:ancestor_well_b1) do
    create(
      :v2_well,
      position: {
        'name' => 'B1'
      },
      qc_results: create_list(:qc_result, 1, qc_result_options),
      submit_for_sequencing: false
    )
  end
  let(:labware) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }
  let(:ancestor_labware) { create(:v2_plate, wells: [ancestor_well_a1, ancestor_well_b1], pool_sizes: [1, 1]) }

  before do
    assign(:plate, labware)
    assign(:ancestor_plate, ancestor_labware)
  end

  let(:expected_content) do
    [
      ['Well', 'Concentration (ng/ul)', 'Submit for sequencing (Y/N)?', 'Sub-Pool', 'Coverage'],
      %w[A1 1.5 Y 1 15],
      ['B1', '1.5', 'N', nil, nil]
    ]
  end

  it 'renders the expected content' do
    expect(CSV.parse(render)).to eq(expected_content)
  end
end
