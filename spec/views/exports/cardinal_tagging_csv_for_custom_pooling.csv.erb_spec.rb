# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/cardinal_tagging_csv_for_custom_pooling.csv.erb' do
  has_a_working_api

  let(:well_a1) { create(:v2_tagged_well, position: { 'name' => 'A1' }) }
  let(:well_b1) { create(:v2_tagged_well, position: { 'name' => 'B1' }) }
  let(:labware) { create(:v2_plate, wells: [well_a1, well_b1]) }

  before do
    assign(:plate, labware)
  end

  let(:expected_headers) do
    ['Source Well', 'Volume to add to pool', 'Dest. pool', 'Number of samples', 'Tag index', 'Tag 2 index']
  end

  def get_column(csv, index)
    csv[1..-2].map { |r| r[index] }
  end

  it 'renders the expected content' do
    parsed_csv = CSV.parse(render)
    expect(parsed_csv.size).to eq 4 # last line is empty
    expect(parsed_csv[3]).to eq []
    expect(parsed_csv[0]).to eq(expected_headers)

    # Check one column at a time
    barcode = labware.labware_barcode.human
    expect(get_column(parsed_csv, 0)).to eq(["#{barcode}:A1", "#{barcode}:B1"])
    expect(get_column(parsed_csv, 1)).to eq([nil, nil])
    expect(get_column(parsed_csv, 2)).to eq([nil, nil])

    # TODO: DPL-071 Check number of samples are correct when they're not random
    #       For now, just check they are integers.
    expect(get_column(parsed_csv, 3)).to all(satisfy { |val| true if Integer(val) rescue false })

    expect(get_column(parsed_csv, 4)).to eq([well_a1.aliquots[0].tag_index.to_s, well_b1.aliquots[0].tag_index.to_s])
    expect(get_column(parsed_csv, 5)).to eq([well_a1.aliquots[0].tag2_index.to_s, well_b1.aliquots[0].tag2_index.to_s])
  end

  # it 'removes entries with no qc results' do
  #   ancestor_labware.wells_in_columns[0].qc_results = []

  #   expected = [
  #     %w[SourcePlate SourceWell DestinationPlate DestinationWell SampleVolume ResuspensionVolume],
  #     [ancestor_plate_barcode, 'B1', labware.labware_barcode.human, 'A1', '14.29', '3.125'],
  #     [ancestor_plate_barcode, 'C1', labware.labware_barcode.human, 'B1', '10.81', '3.125']
  #   ]

  #   expect(CSV.parse(render)).to eq(expected)
  # end

  # it 'removes entries with no cell count results' do
  #   ancestor_labware.wells_in_columns[0].qc_results.shift

  #   expected = [
  #     %w[SourcePlate SourceWell DestinationPlate DestinationWell SampleVolume ResuspensionVolume],
  #     [ancestor_plate_barcode, 'B1', labware.labware_barcode.human, 'A1', '14.29', '3.125'],
  #     [ancestor_plate_barcode, 'C1', labware.labware_barcode.human, 'B1', '10.81', '3.125']
  #   ]

  #   expect(CSV.parse(render)).to eq(expected)
  # end
end
