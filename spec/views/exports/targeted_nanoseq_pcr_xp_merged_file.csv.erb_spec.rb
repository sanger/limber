# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/targeted_nanoseq_pcr_xp_merged_file.csv.erb' do
  let(:qc_result_options_a1) { { value: 1.5, key: 'concentration', units: 'ng/ul' } }
  let(:qc_result_options_b1) { { value: 1.2, key: 'concentration', units: 'ng/ul' } }

  let(:req1_pm1) { build :poly_metadatum, key: 'original_plate_barcode', value: 'BC1' }
  let(:req1_pm2) { build :poly_metadatum, key: 'original_well_id', value: 'A1' }
  let(:req1_pm3) { build :poly_metadatum, key: 'concentration_nm', value: 1.2 }
  let(:req1_pm4) { build :poly_metadatum, key: 'input_amount_available', value: 23.1 }
  let(:req1_pm5) { build :poly_metadatum, key: 'input_amount_desired', value: 34.2 }
  let(:req1_pm6) { build :poly_metadatum, key: 'hyb_panel', value: 'Test hyb panel' }

  let(:request1) do
    create :library_request_with_poly_metadata,
           poly_metadata: [req1_pm1, req1_pm2, req1_pm3, req1_pm4, req1_pm5, req1_pm6]
  end

  let(:req2_pm1) { build :poly_metadatum, key: 'original_plate_barcode', value: 'BC1' }
  let(:req2_pm2) { build :poly_metadatum, key: 'original_well_id', value: 'B1' }
  let(:req2_pm3) { build :poly_metadatum, key: 'concentration_nm', value: 1.0 }
  let(:req2_pm4) { build :poly_metadatum, key: 'input_amount_available', value: 21.6 }
  let(:req2_pm5) { build :poly_metadatum, key: 'input_amount_desired', value: 35.7 }
  let(:req2_pm6) { build :poly_metadatum, key: 'hyb_panel', value: 'Test hyb panel' }

  let(:request2) do
    create :library_request_with_poly_metadata,
           poly_metadata: [req2_pm1, req2_pm2, req2_pm3, req2_pm4, req2_pm5, req2_pm6]
  end

  let(:well_a1) do
    create(
      :v2_well,
      location: 'A1',
      position: {
        'name' => 'A1'
      },
      qc_results: create_list(:qc_result, 1, qc_result_options_a1),
      outer_request: request1
    )
  end
  let(:well_b1) do
    create(
      :v2_well,
      location: 'B1',
      position: {
        'name' => 'B1'
      },
      qc_results: create_list(:qc_result, 1, qc_result_options_b1),
      outer_request: request2
    )
  end

  let(:labware) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

  let(:well_a1_sanger_id) { well_a1.aliquots.first.sample.sanger_sample_id }
  let(:well_b1_sanger_id) { well_b1.aliquots.first.sample.sanger_sample_id }

  let(:well_a1_supplier_name) { well_a1.aliquots.first.sample.sample_metadata.supplier_name }
  let(:well_b1_supplier_name) { well_b1.aliquots.first.sample.sample_metadata.supplier_name }

  before do
    assign(:plate, labware)
    well_a1.aliquots.first.request = request1
    well_b1.aliquots.first.request = request2
  end

  # NB. poly_metadata values are strings, so all values from poly_metadata will come out as strings in the csv
  let(:expected_content) do
    [
      [
        'Original Plate Barcode',
        'Original Well ID',
        'Concentration (nM)',
        'Sanger Sample ID',
        'Supplier Sample Name',
        'Input amount available (fmol)',
        'Input amount desired (fmol)',
        'New Plate Barcode',
        'New Well ID',
        'Concentration (ng/ul)',
        'Hyb Panel'
      ],
      [
        'BC1',
        'A1',
        '1.2',
        well_a1_sanger_id,
        well_a1_supplier_name,
        '23.1',
        '34.2',
        labware.human_barcode,
        'A1',
        '1.5',
        'Test hyb panel'
      ],
      [
        'BC1',
        'B1',
        '1.0',
        well_b1_sanger_id,
        well_b1_supplier_name,
        '21.6',
        '35.7',
        labware.human_barcode,
        'B1',
        '1.2',
        'Test hyb panel'
      ]
    ]
  end

  it 'renders the expected content' do
    expect(CSV.parse(render)).to eq(expected_content)
  end

  context 'when the wells are rearranged by binning, it orders correctly by original plate and well id' do
    let(:well_a1) do
      create(
        :v2_well,
        location: 'A1',
        position: {
          'name' => 'A1'
        },
        qc_results: create_list(:qc_result, 1, qc_result_options_a1),
        outer_request: request2
      )
    end
    let(:well_b1) do
      create(
        :v2_well,
        location: 'B1',
        position: {
          'name' => 'B1'
        },
        qc_results: create_list(:qc_result, 1, qc_result_options_b1),
        outer_request: request1
      )
    end

    let(:expected_content) do
      [
        [
          'Original Plate Barcode',
          'Original Well ID',
          'Concentration (nM)',
          'Sanger Sample ID',
          'Supplier Sample Name',
          'Input amount available (fmol)',
          'Input amount desired (fmol)',
          'New Plate Barcode',
          'New Well ID',
          'Concentration (ng/ul)',
          'Hyb Panel'
        ],
        [
          'BC1',
          'A1',
          '1.2',
          well_b1_sanger_id,
          well_b1_supplier_name,
          '23.1',
          '34.2',
          labware.human_barcode,
          'B1',
          '1.2',
          'Test hyb panel'
        ],
        [
          'BC1',
          'B1',
          '1.0',
          well_a1_sanger_id,
          well_a1_supplier_name,
          '21.6',
          '35.7',
          labware.human_barcode,
          'A1',
          '1.5',
          'Test hyb panel'
        ]
      ]
    end

    before do
      well_a1.aliquots.first.request = request2
      well_b1.aliquots.first.request = request1
    end

    it 'renders the expected content' do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end
end
