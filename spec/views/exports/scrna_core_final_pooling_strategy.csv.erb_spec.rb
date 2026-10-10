# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/scrna_core_final_pooling_strategy.csv.erb' do
#   let(:tube_a1) { create(:stock_tube, state: 'passed', purpose_name: 'Example Purpose', barcode_number: 2) }
#   let(:tube_b1) { create(:stock_tube, state: 'passed', purpose_name: 'Example Purpose', barcode_number: 3) }
#   let(:tube_c1) { create(:stock_tube, state: 'passed', purpose_name: 'Example Purpose', barcode_number: 4) }
#   let(:tube_e7) { create(:stock_tube, state: 'passed', purpose_name: 'Example Purpose', barcode_number: 5) }
#   let(:tube_g12) { create(:stock_tube, state: 'passed', purpose_name: 'Example Purpose', barcode_number: 6) }

#   let(:well_a1) { create(:stock_well, location: 'A1', state: 'passed', upstream_tubes: [tube_a1]) }
#   let(:well_b1) { create(:stock_well, location: 'B1', state: 'passed', upstream_tubes: [tube_b1]) }
#   let(:well_c1) { create(:stock_well, location: 'C1', state: 'passed', upstream_tubes: [tube_c1]) }
#   let(:well_e7) { create(:stock_well, location: 'E7', state: 'passed', upstream_tubes: [tube_e7]) }
#   let(:well_g12) { create(:stock_well, location: 'G12', state: 'passed', upstream_tubes: [tube_g12]) }

  let(:parent_plate_1) { create(:plate) }
  let(:parent_plate_2) { create(:plate) }
  let(:pools_plate) { create(:plate, parents: [parent_plate_1, parent_plate_2]) }

  before { assign(:plate, pools_plate) }

  def get_column(csv, index)
    csv[1..].pluck(index)
  end

  it 'renders the expected content' do
    parsed_csv = CSV.parse(render)
    # expect(parsed_csv.size).to eq 11
    # barcode = labware.labware_barcode.human

    expected_column_names = ['DONOR ID', 'SAMPLE DESCRIPTION', 'SANGER TUBE ID', 'SANGER SAMPLE ID', 'LRC PBMC Defrost 1ml or Aliquot ID', 'Source Well', 'LRC PBMC Defrost 1ml/ Aliquot plate Total Cells/mL', 'LRC PBMC Defrost 1ml/ Aliquot plate Viability', 'LRC PBMC Defrost 1ml/Aliquot plate Status', 'LRC PBMC Pools plate ID', 'Proposed Destination Well', 'Destination Well', 'LRC PBMC Pools plate Total Cells/mL', 'LRC PBMC Pools plate Viability', 'Requested scRNA Core Cells per Chip Well', 'Actual scRNA Core Cells per Chip Well']
    expect(parsed_csv[0]).to eq expected_column_names

    expected_sample_1 = ['DONOR-1', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
    expect(parsed_csv[1]).to eq expected_sample_1

    # Donor ID column
    # expect(get_column(parsed_csv, 0)).to eq(['DONOR-1', 'DONOR-2', nil])

    # # chek for tube barcode content in wells
    # expect(get_column(parsed_csv, 1)).to eq(
    #   [nil, '1', 'NT2P', 'NT3Q', 'NT4R', 'empty', 'empty', 'empty', 'empty', 'empty']
    # )
    # expect(get_column(parsed_csv, 7)).to eq(
    #   [nil, '7', 'empty', 'empty', 'empty', 'empty', 'NT5S', 'empty', 'empty', 'empty']
    # )
    # expect(get_column(parsed_csv, 12)).to eq(
    #   [nil, '12', 'empty', 'empty', 'empty', 'empty', 'empty', 'empty', 'NT6T', 'empty']
    # )
  end
end
