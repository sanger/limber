# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_lrc_pbmc_defrost_pbs_to_lrc_pbmc_pools.csv.erb' do
  has_a_working_api

  let(:workflow) { 'workflow_name' }

  let(:plate1_barcode) { 'DN1S' }
  let(:plate2_barcode) { 'DN2T' }

  let(:live_cell_count_a1) { create(:qc_result, key: 'live_cell_count', value: '1_000_000', units: 'cells/ml') }
  let(:live_cell_count_b1) { create(:qc_result, key: 'live_cell_count', value: '2_000_000', units: 'cells/ml') }
  let(:live_cell_count_c1) { create(:qc_result, key: 'live_cell_count', value: '3_000_000', units: 'cells/ml') }
  let(:live_cell_count_d1) { create(:qc_result, key: 'live_cell_count', value: '4_000_000', units: 'cells/ml') }

  let(:live_cell_count_a2) { create(:qc_result, key: 'live_cell_count', value: '5_000_000', units: 'cells/ml') }
  let(:live_cell_count_b2) { create(:qc_result, key: 'live_cell_count', value: '6_000_000', units: 'cells/ml') }
  let(:live_cell_count_c2) { create(:qc_result, key: 'live_cell_count', value: '7_000_000', units: 'cells/ml') }
  let(:live_cell_count_d2) { create(:qc_result, key: 'live_cell_count', value: '8_000_000', units: 'cells/ml') }

  let(:live_cell_count_a3) { create(:qc_result, key: 'live_cell_count', value: '9_000_000', units: 'cells/ml') }
  let(:live_cell_count_b3) { create(:qc_result, key: 'live_cell_count', value: '10_000_000', units: 'cells/ml') }
  let(:live_cell_count_c3) { create(:qc_result, key: 'live_cell_count', value: '11_000_000', units: 'cells/ml') }
  let(:live_cell_count_d3) { create(:qc_result, key: 'live_cell_count', value: '12_000_000', units: 'cells/ml') }

  let(:source_well_a1) do
    create(:v2_well, location: 'A1', qc_results: [live_cell_count_a1], plate_barcode: plate1_barcode)
  end
  let(:source_well_b1) do
    create(:v2_well, location: 'B1', qc_results: [live_cell_count_b1], plate_barcode: plate1_barcode)
  end
  let(:source_well_c1) do
    create(:v2_well, location: 'C1', qc_results: [live_cell_count_c1], plate_barcode: plate2_barcode)
  end
  let(:source_well_d1) do
    create(:v2_well, location: 'D1', qc_results: [live_cell_count_d1], plate_barcode: plate2_barcode)
  end

  let(:source_well_a2) do
    create(:v2_well, location: 'A2', qc_results: [live_cell_count_a2], plate_barcode: plate1_barcode)
  end
  let(:source_well_b2) do
    create(:v2_well, location: 'B2', qc_results: [live_cell_count_b2], plate_barcode: plate1_barcode)
  end
  let(:source_well_c2) do
    create(:v2_well, location: 'C2', qc_results: [live_cell_count_c2], plate_barcode: plate2_barcode)
  end
  let(:source_well_d2) do
    create(:v2_well, location: 'D2', qc_results: [live_cell_count_d2], plate_barcode: plate2_barcode)
  end

  let(:source_well_a3) do
    create(:v2_well, location: 'A3', qc_results: [live_cell_count_a3], plate_barcode: plate1_barcode)
  end
  let(:source_well_b3) do
    create(:v2_well, location: 'B3', qc_results: [live_cell_count_b3], plate_barcode: plate1_barcode)
  end
  let(:source_well_c3) do
    create(:v2_well, location: 'C3', qc_results: [live_cell_count_c3], plate_barcode: plate2_barcode)
  end
  let(:source_well_d3) do
    create(:v2_well, location: 'D3', qc_results: [live_cell_count_d3], plate_barcode: plate2_barcode)
  end

  let(:source_plate1_wells) do
    [source_well_a1, source_well_b1, source_well_a2, source_well_b2, source_well_a3, source_well_b3]
  end
  let(:source_plate2_wells) do
    [source_well_c1, source_well_d1, source_well_c2, source_well_d2, source_well_c3, source_well_d3]
  end

  let(:all_source_wells) { source_plate1_wells + source_plate2_wells }

  let(:source_plate1) { create(:v2_plate, wells: source_plate1_wells, barcode_number: 1) }
  let(:source_plate2) { create(:v2_plate, wells: source_plate2_wells, barcode_number: 2) }

  let(:transfer_request1) { create(:v2_transfer_request, source_asset: source_well_a1, target_asset: nil) }
  let(:transfer_request2) { create(:v2_transfer_request, source_asset: source_well_b1, target_asset: nil) }
  let(:transfer_request3) { create(:v2_transfer_request, source_asset: source_well_c1, target_asset: nil) }
  let(:transfer_request4) { create(:v2_transfer_request, source_asset: source_well_d1, target_asset: nil) }

  let(:transfer_request5) { create(:v2_transfer_request, source_asset: source_well_a2, target_asset: nil) }
  let(:transfer_request6) { create(:v2_transfer_request, source_asset: source_well_b2, target_asset: nil) }
  let(:transfer_request7) { create(:v2_transfer_request, source_asset: source_well_c2, target_asset: nil) }
  let(:transfer_request8) { create(:v2_transfer_request, source_asset: source_well_d2, target_asset: nil) }

  let(:transfer_request9) { create(:v2_transfer_request, source_asset: source_well_a3, target_asset: nil) }
  let(:transfer_request10) { create(:v2_transfer_request, source_asset: source_well_b3, target_asset: nil) }
  let(:transfer_request11) { create(:v2_transfer_request, source_asset: source_well_c3, target_asset: nil) }
  let(:transfer_request12) { create(:v2_transfer_request, source_asset: source_well_d3, target_asset: nil) }

  let(:transfers_to_a1) do
    [transfer_request1, transfer_request3, transfer_request5, transfer_request7, transfer_request9, transfer_request11]
  end
  let(:transfers_to_b1) do
    [transfer_request2, transfer_request4, transfer_request6, transfer_request8, transfer_request10, transfer_request12]
  end

  let(:dest_well_a1) do
    create(
      :v2_well_with_transfer_requests,
      location: 'A1',
      transfer_requests_as_target: transfers_to_a1,
      plate_barcode: 'DN3U'
    )
  end

  let(:dest_well_b1) do
    create(
      :v2_well_with_transfer_requests,
      location: 'B1',
      transfer_requests_as_target: transfers_to_b1,
      plate_barcode: 'DN3U'
    )
  end

  let(:dest_plate) { create(:v2_plate, wells: [dest_well_a1, dest_well_b1], barcode_number: 3) }

  let(:expected_content) do
    [
      ['Workflow', workflow],
      [],
      [
        'Source Plate',
        'Source Well',
        'Destination Plate',
        'Destination Well',
        'Sample Volume (µL)',
        'Resuspension Volume (µL)'
      ],
      %w[DN1S A1 DN3U A1 5.00 13.20],
      %w[DN1S B1 DN3U B1 2.50 13.20],
      %w[DN1S A2 DN3U A1 1.00 13.20],
      %w[DN1S B2 DN3U B1 0.83 13.20],
      %w[DN1S A3 DN3U A1 0.56 13.20],
      %w[DN1S B3 DN3U B1 0.50 13.20],
      %w[DN2T C1 DN3U A1 1.67 13.20],
      %w[DN2T D1 DN3U B1 1.25 13.20],
      %w[DN2T C2 DN3U A1 0.71 13.20],
      %w[DN2T D2 DN3U B1 0.62 13.20],
      %w[DN2T C3 DN3U A1 0.45 13.20],
      %w[DN2T D3 DN3U B1 0.42 13.20]
    ]
  end

  let!(:study) { create(:study_with_poly_metadata, poly_metadata: []) } # empty poly_metadata

  let(:cell_count_key) { 'scrna_core_pbmc_donor_pooling_required_number_of_cells' }
  let(:default_cell_count) { 5000 }

  before do
    assign(:ancestor_plate_list, [source_plate1, source_plate2])
    assign(:workflow, workflow)
    assign(:plate, dest_plate)
    all_source_wells.each { |well| allow(well.aliquots.first).to receive(:study).and_return(study) }
    Settings.purposes = {
      dest_plate.purpose.uuid => {
        presenter_class: {
          args: {
            default_required_number_of_cells: default_cell_count,
            study_required_number_of_cells_key: cell_count_key
          }
        }
      }
    }
  end

  context 'without study-specific cell count option' do
    it 'renders the csv' do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end

  context 'with study-specific cell count option' do
    let!(:study) do
      poly_metadatum = create(:poly_metadatum, key: cell_count_key, value: '9000')
      create(:study_with_poly_metadata, poly_metadata: [poly_metadatum]) # poly_metadata with cell count option
    end

    let(:expected_content) do
      [
        ['Workflow', workflow],
        [],
        [
          'Source Plate',
          'Source Well',
          'Destination Plate',
          'Destination Well',
          'Sample Volume (µL)',
          'Resuspension Volume (µL)'
        ],
        %w[DN1S A1 DN3U A1 9.00 13.20],
        %w[DN1S B1 DN3U B1 4.50 13.20],
        %w[DN1S A2 DN3U A1 1.80 13.20],
        %w[DN1S B2 DN3U B1 1.50 13.20],
        %w[DN1S A3 DN3U A1 1.00 13.20],
        %w[DN1S B3 DN3U B1 0.90 13.20],
        %w[DN2T C1 DN3U A1 3.00 13.20],
        %w[DN2T D1 DN3U B1 2.25 13.20],
        %w[DN2T C2 DN3U A1 1.29 13.20],
        %w[DN2T D2 DN3U B1 1.12 13.20],
        %w[DN2T C3 DN3U A1 0.82 13.20],
        %w[DN2T D3 DN3U B1 0.75 13.20]
      ]
    end
    it 'renders the csv' do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end
end
