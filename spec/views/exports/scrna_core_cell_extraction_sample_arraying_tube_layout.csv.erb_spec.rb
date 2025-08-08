# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/scrna_core_cell_extraction_sample_arraying_tube_layout.csv.erb' do
  let(:tube_a1) { create(:v2_stock_tube, state: 'passed', purpose_name: 'Example Purpose', barcode_number: 2) }
  let(:tube_b1) { create(:v2_stock_tube, state: 'passed', purpose_name: 'Example Purpose', barcode_number: 3) }
  let(:tube_c1) { create(:v2_stock_tube, state: 'passed', purpose_name: 'Example Purpose', barcode_number: 4) }
  let(:tube_e7) { create(:v2_stock_tube, state: 'passed', purpose_name: 'Example Purpose', barcode_number: 5) }
  let(:tube_g12) { create(:v2_stock_tube, state: 'passed', purpose_name: 'Example Purpose', barcode_number: 6) }

  let(:well_a1) { create(:v2_stock_well, location: 'A1', state: 'passed', upstream_tubes: [tube_a1]) }
  let(:well_b1) { create(:v2_stock_well, location: 'B1', state: 'passed', upstream_tubes: [tube_b1]) }
  let(:well_c1) { create(:v2_stock_well, location: 'C1', state: 'passed', upstream_tubes: [tube_c1]) }
  let(:well_e7) { create(:v2_stock_well, location: 'E7', state: 'passed', upstream_tubes: [tube_e7]) }
  let(:well_g12) { create(:v2_stock_well, location: 'G12', state: 'passed', upstream_tubes: [tube_g12]) }

  let(:labware) { create(:v2_plate, barcode_number: 1, wells: [well_a1, well_b1, well_c1, well_e7, well_g12]) }

  before { assign(:plate, labware) }

  def get_column(csv, index)
    csv[1..].pluck(index)
  end

  it 'renders the expected content' do
    parsed_csv = CSV.parse(render)
    expect(parsed_csv.size).to eq 11
    barcode = labware.labware_barcode.human
    expected_plate_header = ['Plate Barcode', barcode]
    expect(parsed_csv[0]).to eq expected_plate_header

    # check for row headers in column 1
    expect(get_column(parsed_csv, 0)).to eq([nil, nil, 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'])

    # chek for tube barcode content in wells
    expect(get_column(parsed_csv, 1)).to eq(
      [nil, '1', 'NT2P', 'NT3Q', 'NT4R', 'empty', 'empty', 'empty', 'empty', 'empty']
    )
    expect(get_column(parsed_csv, 7)).to eq(
      [nil, '7', 'empty', 'empty', 'empty', 'empty', 'NT5S', 'empty', 'empty', 'empty']
    )
    expect(get_column(parsed_csv, 12)).to eq(
      [nil, '12', 'empty', 'empty', 'empty', 'empty', 'empty', 'empty', 'NT6T', 'empty']
    )
  end
end
