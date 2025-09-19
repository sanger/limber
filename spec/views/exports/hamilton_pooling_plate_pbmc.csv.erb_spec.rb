# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_pooling_plate_pbmc.csv.erb' do
  let(:ancestor_plate_barcode) { 'ANCESTOR_PLATE' }
  let(:concentration_result) { create(:qc_result_concentration) }
  let(:live_cell_count_a1) { create(:qc_result, key: 'live_cell_count', value: '1000000', units: 'cells/ml') }
  let(:live_cell_count_b1) { create(:qc_result, key: 'live_cell_count', value: '1400000', units: 'cells/ml') }
  let(:live_cell_count_c1) { create(:qc_result, key: 'live_cell_count', value: '1850000', units: 'cells/ml') }

  let(:ancestor_well_a1) do
    create(
      :well,
      plate_barcode: ancestor_plate_barcode,
      location: 'A1',
      qc_results: [live_cell_count_a1, concentration_result]
    )
  end
  let(:ancestor_well_b1) do
    create(:well, plate_barcode: ancestor_plate_barcode, location: 'B1', qc_results: [live_cell_count_b1])
  end
  let(:ancestor_well_c1) do
    create(:well, plate_barcode: ancestor_plate_barcode, location: 'C1', qc_results: [live_cell_count_c1])
  end
  let(:ancestor_wells_group_1) do
    %w[A2 B2 C2 D2 E2 F2 G2 H2 A3 B3 C3 D3].map do |coord|
      create(:well, plate_barcode: ancestor_plate_barcode, location: coord, qc_results: [live_cell_count_c1])
    end
  end
  let(:ancestor_wells_group_2) do
    %w[A4 B4 C4 D4 E4 F4 G4 H4 A5 B5 C5 D5 E5].map do |coord|
      create(:well, plate_barcode: ancestor_plate_barcode, location: coord, qc_results: [live_cell_count_c1])
    end
  end
  let(:ancestor_wells) do
    [ancestor_well_a1, ancestor_well_b1, ancestor_well_c1] + ancestor_wells_group_1 + ancestor_wells_group_2
  end

  let(:ancestor_labware) { create(:plate, wells: ancestor_wells, pool_sizes: ancestor_wells.map { |_well| 1 }) }

  let(:transfer_requests) do
    ancestor_wells.map { |well| create(:transfer_request, source_asset: well, target_asset: nil) }
  end

  let(:well_a1) do
    create(
      :well_with_transfer_requests,
      position: {
        'name' => 'A1'
      },
      transfer_requests_as_target: transfer_requests[0..1]
    )
  end
  let(:well_b1) do
    create(
      :well_with_transfer_requests,
      position: {
        'name' => 'B1'
      },
      transfer_requests_as_target: [transfer_requests[2]]
    )
  end
  let(:well_c1) do
    create(
      :well_with_transfer_requests,
      position: {
        'name' => 'C1'
      },
      transfer_requests_as_target: transfer_requests[3..(3 + ancestor_wells_group_1.count - 1)]
    )
  end
  let(:well_d1) do
    create(
      :well_with_transfer_requests,
      position: {
        'name' => 'D1'
      },
      transfer_requests_as_target: transfer_requests[(3 + ancestor_wells_group_1.count)..]
    )
  end
  let(:labware) do
    create(
      :plate,
      wells: [well_a1, well_b1, well_c1, well_d1],
      pool_sizes: [2, 1, ancestor_wells_group_1.count, ancestor_wells_group_2.count]
    )
  end

  before do
    assign(:ancestor_plate, ancestor_labware)
    assign(:plate, labware)
  end

  let(:expected_content) do
    [
      %w[SourcePlate SourceWell DestinationPlate DestinationWell SampleVolume ResuspensionVolume],
      [ancestor_plate_barcode, 'A1', labware.labware_barcode.human, 'A1', '20.00', '20.00'],
      # rubocop:todo Layout/LineLength
      [ancestor_plate_barcode, 'B1', labware.labware_barcode.human, 'A1', '14.29', '20.00'], # Sample volume rounded up from 14.2857
      # rubocop:enable Layout/LineLength
      [ancestor_plate_barcode, 'C1', labware.labware_barcode.human, 'B1', '10.81', '20.00'],
      [ancestor_plate_barcode, 'A2', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'B2', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'C2', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'D2', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'E2', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'F2', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'G2', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'H2', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'A3', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'B3', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'C3', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'D3', labware.labware_barcode.human, 'C1', '10.81', '26.40'],
      [ancestor_plate_barcode, 'A4', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'B4', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'C4', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'D4', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'E4', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'F4', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'G4', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'H4', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'A5', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'B5', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'C5', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'D5', labware.labware_barcode.human, 'D1', '10.81', '28.60'],
      [ancestor_plate_barcode, 'E5', labware.labware_barcode.human, 'D1', '10.81', '28.60']
    ]
  end

  it 'renders the expected content' do
    expect(CSV.parse(render)).to eq(expected_content)
  end

  it 'removes entries with no qc results' do
    ancestor_labware.wells_in_columns[0].qc_results = []

    expected_content.delete_at(1)

    expect(CSV.parse(render)).to eq(expected_content)
  end

  it 'removes entries with no cell count results' do
    ancestor_labware.wells_in_columns[0].qc_results.shift

    expected_content.delete_at(1)

    expect(CSV.parse(render)).to eq(expected_content)
  end
end
