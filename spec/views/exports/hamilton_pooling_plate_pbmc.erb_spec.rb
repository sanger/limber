# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_pooling_plate_pbmc.erb' do
  has_a_working_api

  let(:ancestor_plate_barcode) { 'ANCESTOR_PLATE' }
  let(:ancestor_well_a1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'A1') }
  let(:ancestor_well_b1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'B1') }
  let(:ancestor_well_c1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'C1') }
  let(:ancestor_labware) { create(:v2_plate, wells: [ancestor_well_a1, ancestor_well_b1, ancestor_well_c1], pool_sizes: [1, 1, 1]) }

  let(:transfer_request_from_a1) do
    create(
      :v2_transfer_request,
      source_asset: ancestor_well_a1,
      target_asset: nil,
    )
  end
  let(:transfer_request_from_b1) do
    create(
      :v2_transfer_request,
      source_asset: ancestor_well_b1,
      target_asset: nil,
    )
  end
  let(:transfer_request_from_c1) do
    create(
      :v2_transfer_request,
      source_asset: ancestor_well_c1,
      target_asset: nil,
    )
  end

  let(:well_a1) do
    create(
      :v2_well_with_transfer_requests,
      position: { 'name' => 'A1' },
      transfer_requests_as_target: [transfer_request_from_a1, transfer_request_from_b1],
    )
  end
  let(:well_b1) do
    create(
      :v2_well_with_transfer_requests,
      position: { 'name' => 'B1' },
      transfer_requests_as_target: [transfer_request_from_c1],
    )
  end
  let(:labware) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [2, 1]) }

  before do
    assign(:ancestor_plate, ancestor_labware)
    assign(:plate, labware)
  end

  let(:expected_content) do
    [
      ['SourcePlate', 'SourceWell', 'DestinationPlate', 'DestinationWell', 'SampleVolume', 'ResuspensionVolume'],
      [ancestor_plate_barcode, 'A1', labware.labware_barcode.human, 'A1', '1', '31.25'],
      [ancestor_plate_barcode, 'B1', labware.labware_barcode.human, 'A1', '1', '31.25'],
      [ancestor_plate_barcode, 'C1', labware.labware_barcode.human, 'B1', '2', '31.25'],
    ]
  end

  it 'renders the expected content' do
    expect(CSV.parse(render)).to eq(expected_content)
  end
end
