# frozen_string_literal: true

require 'spec_helper'

# Test for export Hamilton LRC PBMC Pools (or Input) to LRC GEM-X 5p Chip
RSpec.describe 'exports/hamilton_gem_x_5p_chip_loading.csv.erb' do
  let(:workflow) { 'scRNA Core GEM-X 5p Chip Loading' }

  # Destination wells are mapped to numbers: A1 -> 17, A2 -> 18, ..., A8 -> 24
  let(:mapping) { ('A1'..'A8').zip((17..24).map(&:to_s)).to_h }

  let(:aliquots_a1) { create_list(:v2_aliquot, 2) }
  let(:aliquots_b1) { create_list(:v2_aliquot, 10) }
  # Source wells
  let(:source_well_a1) { create(:v2_well, location: 'A1', aliquots:aliquots_a1) }
  let(:source_well_b1) { create(:v2_well, location: 'B1', aliquots:aliquots_b1 ) }

  # Transfer requests from source wells
  let(:transfer_request1) { create(:v2_transfer_request, source_asset: source_well_a1, target_asset: nil) }
  let(:transfer_request2) { create(:v2_transfer_request, source_asset: source_well_b1, target_asset: nil) }

  # Destination wells
  let(:dest_well_a1) do
    create(:v2_well_with_transfer_requests, location: 'A1', transfer_requests_as_target: [transfer_request1])
  end
  let(:dest_well_a2) do
    create(:v2_well_with_transfer_requests, location: 'A2', transfer_requests_as_target: [transfer_request2])
  end

  # Plates
  let(:source_plate) { create(:v2_plate, wells: [source_well_a1, source_well_b1], barcode_number: 1) }
  let(:dest_plate) { create(:v2_plate, wells: [dest_well_a1, dest_well_a2], barcode_number: 2) }

  # Expected content
  let(:workflow_row) { ['Workflow', workflow] }
  let(:empty_row) { [] }
  let(:header_row) do
    [
      'Source Plate ID',
      'Source Plate Well',
      'Destination Plate ID',
      'Destination Plate Well',
      'Source Well Volume',
      'Sample Volume',
      'PBS Volume'
    ]
  end

  # The number of samples is 2, so the sample volume is 13.81 µL ((2*30000*0.95238)/2400 -10.0)
  let(:row_source_a1) do
    [
      source_plate.barcode.human,
      source_well_a1.location,
      dest_plate.barcode.human,
      mapping[dest_well_a1.location],
      '13.81',
      '37.50',
      '0.00'
    ]
  end
  # The number of samples is 10, so the sample volume is 109.05 µL ((10*30000*0.95238)/2400 -10.0)
  let(:row_source_b1) do
    [
      source_plate.barcode.human,
      source_well_b1.location,
      dest_plate.barcode.human,
      mapping[dest_well_a2.location],
      '109.05',
      '37.50',
      '0.00'
    ]
  end

  before do
    assign(:workflow, workflow)
    assign(:plate, dest_plate)
    assign(:ancestor_plate, source_plate) # parent plate
  end

  it 'renders the expected content' do
    rows = CSV.parse(render)
    expect(rows[0]).to eq(workflow_row)
    expect(rows[1]).to eq(empty_row)
    expect(rows[2]).to eq(header_row)
    expect(rows[3]).to eq(row_source_a1)
    expect(rows[4]).to eq(row_source_b1)
  end
end
