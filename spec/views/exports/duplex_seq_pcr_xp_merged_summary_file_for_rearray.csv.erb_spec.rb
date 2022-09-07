# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/duplex_seq_pcr_xp_merged_summary_file_for_rearray.csv.erb' do
  has_a_working_api

  let(:ancestor_qc_result_options) { { value: 1.5, key: 'molarity', units: 'nM' } }
  let(:xp_qc_result_options) { { value: 2.4, key: 'concentration', units: 'ng/ul' } }
  let(:library_type_name) { 'example_library' }
  let(:submission_uuid) { 'sub-uuid' }
  let(:submission_for_cleanup_id) { '1' }
  let(:submission_for_cleanup) { create :v2_submission, id: submission_for_cleanup_id, uuid: submission_uuid }
  let(:bait_library_1) { create :bait_library, name: 'HybPanel1' }
  let(:stock_plate) { create(:v2_stock_plate_for_plate, barcode_number: 1) }

  # dilution and cleanup requests
  let(:request_a1) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-a1',
           library_type: library_type_name,
           input_amount_desired: 50.0,
           diluent_volume: 25.0,
           pcr_cycles: 14,
           submit_for_sequencing: true,
           sub_pool: 1,
           coverage: 15,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:request_b1) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-b1',
           library_type: library_type_name,
           input_amount_desired: 45.0,
           diluent_volume: 24.9,
           pcr_cycles: 12,
           submit_for_sequencing: false,
           sub_pool: 1,
           coverage: 16,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  # xp plate setup - the plate on which the report is generated
  # xp well aliquots would have the link to the requests
  let(:xp_aliquot_a1) { create(:v2_aliquot, request: request_a1) }
  let(:xp_aliquot_b1) { create(:v2_aliquot, request: request_b1) }

  # xp plate wells
  let(:xp_well_a1) do
    create(
      :v2_well,
      location: 'A1',
      aliquots: [xp_aliquot_a1],
      qc_results: create_list(:qc_result, 1, xp_qc_result_options),
      outer_request: request_a1,
      requests_as_target: [request_a1]
    )
  end
  let(:xp_well_b1) do
    create(
      :v2_well,
      location: 'B1',
      aliquots: [xp_aliquot_b1],
      qc_results: create_list(:qc_result, 1, xp_qc_result_options),
      outer_request: request_b1,
      requests_as_target: [request_b1]
    )
  end

  # xp plate
  let(:xp_plate) do
    create(:v2_plate, stock_plate: stock_plate, wells: [xp_well_a1, xp_well_b1], pool_sizes: [1, 1], barcode_number: 3)
  end

  # ancestor plate setup - the plate before the re-array of wells (the AL Lib plate)
  # ancestor plate aliquots are linked to the requests
  let(:ancestor_aliquot_a1) { create(:v2_aliquot, request: request_a1) }
  let(:ancestor_aliquot_b1) { create(:v2_aliquot, request: request_b1) }

  # ancestor plate wells
  let(:ancestor_well_a1) do
    create(
      :v2_well,
      location: 'A1',
      aliquots: [ancestor_aliquot_a1],
      qc_results: create_list(:qc_result, 1, ancestor_qc_result_options),
      outer_request: request_a1
    )
  end
  let(:ancestor_well_b1) do
    create(
      :v2_well,
      location: 'B1',
      aliquots: [ancestor_aliquot_b1],
      qc_results: create_list(:qc_result, 1, ancestor_qc_result_options),
      outer_request: request_b1
    )
  end

  # ancestor plate
  let(:ancestor_plate) do
    create(
      :v2_plate,
      stock_plate: stock_plate,
      wells: [ancestor_well_a1, ancestor_well_b1],
      pool_sizes: [1, 1],
      barcode_number: 2
    )
  end

  before do
    assign(:plate, xp_plate)
    assign(:ancestor_plate, ancestor_plate)
  end

  # NB. input amount available = 25 * molarity e.g. 25 * 1.5 = 37.5
  let(:expected_content) do
    [
      [
        'LDS Stock Barcode',
        'LDS Stock Well Id',
        'Concentration (nM)',
        'Sanger Sample Id',
        'Supplier Sample Name',
        'Input amount available (fmol)',
        'Input amount desired',
        'LDS Lib PCR XP Barcode',
        'LDS Lib PCR XP Well ID',
        'Concentration (ng/ul)',
        'Submit for sequencing (Y/N)?',
        'Sub-Pool',
        'Coverage',
        'Hyb panel'
      ],
      [
        stock_plate.labware_barcode.human,
        'A1',
        '1.5',
        ancestor_well_a1.sanger_sample_id&.to_s,
        ancestor_well_a1.supplier_name,
        '37.5',
        '50.0',
        xp_plate.labware_barcode.human,
        'A1',
        '2.4',
        'Y',
        '1',
        '15',
        bait_library_1.name
      ],
      [
        stock_plate.labware_barcode.human,
        'B1',
        '1.5',
        ancestor_well_b1.sanger_sample_id&.to_s,
        ancestor_well_b1.supplier_name,
        nil,
        nil,
        xp_plate.labware_barcode.human,
        'B1',
        nil,
        'N',
        nil,
        nil,
        nil
      ]
    ]
  end

  it 'renders the expected content' do
    expect(CSV.parse(render)).to eq(expected_content)
  end
end
