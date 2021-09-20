# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_pooling_plate_pbmc.erb' do
  has_a_working_api

  let(:ancestor_plate_barcode) { 'ANCESTOR_PLATE' }
  let(:concentration_result) { create(:qc_result_concentration) }
  let(:live_cell_count_a1) { create(:qc_result, key: 'live_cell_count', value: '1000000', units: 'cells/ml') }
  let(:live_cell_count_b1) { create(:qc_result, key: 'live_cell_count', value: '1400000', units: 'cells/ml') }
  let(:live_cell_count_c1) { create(:qc_result, key: 'live_cell_count', value: '1850000', units: 'cells/ml') }
  let(:ancestor_well_a1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'A1', qc_results: [live_cell_count_a1, concentration_result]) }
  let(:ancestor_well_b1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'B1', qc_results: [live_cell_count_b1]) }
  let(:ancestor_well_c1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'C1', qc_results: [live_cell_count_c1]) }
  let(:ancestor_labware) { create(:v2_plate, wells: [ancestor_well_a1, ancestor_well_b1, ancestor_well_c1], pool_sizes: [1, 1, 1]) }

  let(:transfer_request_from_a1) { create(:v2_transfer_request, source_asset: ancestor_well_a1, target_asset: nil) }
  let(:transfer_request_from_b1) { create(:v2_transfer_request, source_asset: ancestor_well_b1, target_asset: nil) }
  let(:transfer_request_from_c1) { create(:v2_transfer_request, source_asset: ancestor_well_c1, target_asset: nil) }
  let(:well_a1) do
    create(
      :v2_well_with_transfer_requests,
      position: { 'name' => 'A1' },
      transfer_requests_as_target: [transfer_request_from_a1, transfer_request_from_b1]
    )
  end
  let(:well_b1) do
    create(
      :v2_well_with_transfer_requests,
      position: { 'name' => 'B1' },
      transfer_requests_as_target: [transfer_request_from_c1]
    )
  end
  let(:labware) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [2, 1]) }

  before do
    assign(:ancestor_plate, ancestor_labware)
    assign(:plate, labware)
  end

  let(:expected_content) do
    [
      %w[SourcePlate SourceWell DestinationPlate DestinationWell SampleVolume ResuspensionVolume],
      [ancestor_plate_barcode, 'A1', labware.labware_barcode.human, 'A1', '20.00', '6.25'],
      [ancestor_plate_barcode, 'B1', labware.labware_barcode.human, 'A1', '14.29', '6.25'],  # Rounded up from 14.2857
      [ancestor_plate_barcode, 'C1', labware.labware_barcode.human, 'B1', '10.81', '3.125']
    ]
  end

  it 'renders the expected content' do
    expect(CSV.parse(render)).to eq(expected_content)
  end

  it 'removes entries with no qc results' do
    ancestor_labware.wells_in_columns[0].qc_results = []

    expected = [
      %w[SourcePlate SourceWell DestinationPlate DestinationWell SampleVolume ResuspensionVolume],
      [ancestor_plate_barcode, 'B1', labware.labware_barcode.human, 'A1', '14.29', '3.125'],
      [ancestor_plate_barcode, 'C1', labware.labware_barcode.human, 'B1', '10.81', '3.125']
    ]

    expect(CSV.parse(render)).to eq(expected)
  end

  it 'removes entries with no cell count results' do
    ancestor_labware.wells_in_columns[0].qc_results.shift

    expected = [
      %w[SourcePlate SourceWell DestinationPlate DestinationWell SampleVolume ResuspensionVolume],
      [ancestor_plate_barcode, 'B1', labware.labware_barcode.human, 'A1', '14.29', '3.125'],
      [ancestor_plate_barcode, 'C1', labware.labware_barcode.human, 'B1', '10.81', '3.125']
    ]

    expect(CSV.parse(render)).to eq(expected)
  end
end
