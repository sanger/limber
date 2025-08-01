# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_lrc_blood_bank_to_lrc_pbmc_bank.csv.erb' do
  # workflow
  let(:workflow) { 'workflow_name' }

  # samples
  let(:sample1_uuid) { 'sample1_uuid' }
  let(:sample2_uuid) { 'sample2_uuid' }

  let(:sample1) { create(:v2_sample, name: 'sample1_name', uuid: sample1_uuid) }
  let(:sample2) { create(:v2_sample, name: 'sample2_name', uuid: sample2_uuid) }

  # ancestor vac tubes
  let(:vac_aliquot1) { create(:v2_aliquot, sample: sample1) }
  let(:vac_aliquot2) { create(:v2_aliquot, sample: sample2) }

  let(:ancestor_vac_tube_1) { create(:v2_tube, barcode_number: 1, aliquots: [vac_aliquot1]) }
  let(:ancestor_vac_tube_2) { create(:v2_tube, barcode_number: 2, aliquots: [vac_aliquot2]) }

  # ancestor tubes hash
  let(:ancestor_tubes) { { sample1_uuid => ancestor_vac_tube_1, sample2_uuid => ancestor_vac_tube_2 } }

  # source plate
  let(:source_aliquot1) { create(:v2_aliquot, sample: sample1) }
  let(:source_aliquot2) { create(:v2_aliquot, sample: sample2) }
  let(:source_aliquot3) { create(:v2_aliquot, sample: sample1) } # same sample as source_aliquot1

  let(:source_well_a1) { create(:v2_well, location: 'A1', aliquots: [source_aliquot1]) }
  let(:source_well_b1) { create(:v2_well, location: 'B1', aliquots: [source_aliquot2]) }
  let(:source_well_a2) { create(:v2_well, location: 'A2', aliquots: [source_aliquot3]) } # same row as source_well_a1

  let(:source_plate) { create(:v2_plate, wells: [source_well_a1, source_well_b1, source_well_a2], barcode_number: 1) }

  # transfer requests
  let(:transfer_request1) { create(:v2_transfer_request, source_asset: source_well_a1, target_asset: nil) }
  let(:transfer_request2) { create(:v2_transfer_request, source_asset: source_well_b1, target_asset: nil) }

  # transfer_request3 has the same target as transfer_request1 because
  # they have the same sample and the default number of sources config is 2
  let(:transfer_request3) { create(:v2_transfer_request, source_asset: source_well_a2, target_asset: nil) }

  # destination plate
  let(:dest_well_a1) do
    # source: [A1, A2] -> target: A1
    create(
      :v2_well_with_transfer_requests,
      location: 'A1',
      transfer_requests_as_target: [transfer_request1, transfer_request3]
    )
  end
  let(:dest_well_b1) do
    # source: [B1] -> target: B1
    create(:v2_well_with_transfer_requests, location: 'B1', transfer_requests_as_target: [transfer_request2])
  end

  let(:dest_plate) { create(:v2_plate, wells: [dest_well_a1, dest_well_b1], barcode_number: 2) }

  let(:workflow_row) { ['Workflow', workflow] }
  let(:empty_row) { [] }
  let(:header_row) do
    [
      'Source Plate ID',
      'Source Plate Well',
      'Destination Plate ID',
      'Destination Plate Well',
      'Sample Vac Tube ID',
      'Sample Name'
    ]
  end
  let(:row1) do
    [
      source_plate.labware_barcode.human,
      source_well_a1.location,
      dest_plate.labware_barcode.human,
      dest_well_a1.location,
      ancestor_vac_tube_1.labware_barcode.human,
      sample1.name
    ]
  end
  let(:row2) do
    [
      source_plate.labware_barcode.human,
      source_well_a2.location,
      dest_plate.labware_barcode.human,
      dest_well_a1.location,
      ancestor_vac_tube_1.labware_barcode.human,
      sample1.name
    ]
  end
  let(:row3) do
    [
      source_plate.labware_barcode.human,
      source_well_b1.location,
      dest_plate.labware_barcode.human,
      dest_well_b1.location,
      ancestor_vac_tube_2.labware_barcode.human,
      sample2.name
    ]
  end

  before do
    assign(:workflow, workflow)
    assign(:plate, dest_plate)
    assign(:ancestor_plate, source_plate) # parent plate
    assign(:ancestor_tubes, ancestor_tubes)
  end

  it 'renders expected content' do
    lines = CSV.parse(render)
    expect(lines[0]).to eq(workflow_row)
    expect(lines[1]).to eq(empty_row)
    expect(lines[2]).to eq(header_row)
    expect(lines[3]).to eq(row1)
    expect(lines[4]).to eq(row2)
    expect(lines[5]).to eq(row3)
  end
end
