# frozen_string_literal: true

require 'support/shared_examples/dilution_calculations_shared_examples'

RSpec.describe Utility::ConcentrationBinningCalculator do
  context 'when computing values for concentration binning' do
    let(:assay_version) { 'v1.0' }
    let(:parent_uuid) { 'example-plate-uuid' }
    let(:plate_size) { 96 }
    let(:num_rows) { 8 }
    let(:num_cols) { 12 }

    let(:well_a1) do
      create(:v2_well,
             position: { 'name' => 'A1' },
             qc_results: create_list(:qc_result_concentration, 1, value: 1.5))
    end
    let(:well_b1) do
      create(:v2_well,
             position: { 'name' => 'B1' },
             qc_results: create_list(:qc_result_concentration, 1, value: 56.0))
    end
    let(:well_c1) do
      create(:v2_well,
             position: { 'name' => 'C1' },
             qc_results: create_list(:qc_result_concentration, 1, value: 3.5))
    end
    let(:well_d1) do
      create(:v2_well,
             position: { 'name' => 'D1' },
             qc_results: create_list(:qc_result_concentration, 1, value: 1.8))
    end

    let(:parent_plate) do
      create :v2_plate,
             uuid: parent_uuid,
             barcode_number: '2',
             size: plate_size,
             wells: [well_a1, well_b1, well_c1, well_d1],
             outer_requests: requests
    end

    let(:requests) { Array.new(4) { |i| create :library_request, state: 'started', uuid: "request-#{i}" } }

    let(:dilutions_config) do
      {
        'source_volume' => 10,
        'diluent_volume' => 25,
        'bins' => [
          { 'colour' => 1, 'pcr_cycles' => 16, 'max' => 25 },
          { 'colour' => 2, 'pcr_cycles' => 12, 'min' => 25, 'max' => 500 },
          { 'colour' => 3, 'pcr_cycles' => 8, 'min' => 500 }
        ]
      }
    end

    subject { Utility::ConcentrationBinningCalculator.new(dilutions_config) }

    describe '#source_multiplication_factor' do
      it 'calculates the value correctly' do
        expect(subject.source_multiplication_factor).to eq(10.0)
      end
    end

    describe '#dest_multiplication_factor' do
      it 'calculates the value correctly' do
        expect(subject.dest_multiplication_factor).to eq(35.0)
      end
    end

    describe '#compute_well_amounts' do
      let(:src_mult_fact) { subject.source_multiplication_factor }

      it 'calculates plate well amounts correctly' do
        expected_amounts = {
          'A1' => BigDecimal('15.0'),
          'B1' => BigDecimal('560.0'),
          'C1' => BigDecimal('35.0'),
          'D1' => BigDecimal('18.0')
        }

        expect(subject.compute_well_amounts(parent_plate, src_mult_fact)).to eq(expected_amounts)
      end
    end

    describe '#compute_well_transfers' do
      context 'for a simple example with few wells' do
        let(:expd_transfers_simple) do
          {
            'A1' => { 'dest_locn' => 'A1', 'dest_conc' => '0.429' },
            'B1' => { 'dest_locn' => 'A3', 'dest_conc' => '16.0' },
            'C1' => { 'dest_locn' => 'A2', 'dest_conc' => '1.0' },
            'D1' => { 'dest_locn' => 'B1', 'dest_conc' => '0.514' }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate)).to eq(expd_transfers_simple)
        end
      end

      context 'when all wells fall in the same bin' do
        let(:well_a1) do
          create(:v2_well,
                 position: { 'name' => 'A1' },
                 qc_results: create_list(:qc_result_concentration, 1, value: 3.5))
        end
        let(:well_b1) do
          create(:v2_well,
                 position: { 'name' => 'B1' },
                 qc_results: create_list(:qc_result_concentration, 1, value: 3.5))
        end
        let(:well_d1) do
          create(:v2_well,
                 position: { 'name' => 'D1' },
                 qc_results: create_list(:qc_result_concentration, 1, value: 3.5))
        end
        let(:expd_transfers_same_bin) do
          {
            'A1' => { 'dest_locn' => 'A1', 'dest_conc' => '1.0' },
            'B1' => { 'dest_locn' => 'B1', 'dest_conc' => '1.0' },
            'C1' => { 'dest_locn' => 'C1', 'dest_conc' => '1.0' },
            'D1' => { 'dest_locn' => 'D1', 'dest_conc' => '1.0' }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate)).to eq(expd_transfers_same_bin)
        end
      end
    end

    describe '#compute_well_transfers_hash' do
      context 'for a simple example with few wells' do
        let(:well_amounts) do
          {
            'A1' => BigDecimal('15.0'),
            'B1' => BigDecimal('560.0'),
            'C1' => BigDecimal('35.0'),
            'D1' => BigDecimal('18.0')
          }
        end
        let(:expd_transfers) do
          {
            'A1' => { 'dest_locn' => 'A1', 'dest_conc' => '0.429' },
            'B1' => { 'dest_locn' => 'A3', 'dest_conc' => '16.0' },
            'C1' => { 'dest_locn' => 'A2', 'dest_conc' => '1.0' },
            'D1' => { 'dest_locn' => 'B1', 'dest_conc' => '0.514' }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers_hash(well_amounts, num_rows, num_cols)).to eq(expd_transfers)
        end
      end

      context 'when all wells fall in the same bin' do
        let(:well_amounts) do
          {
            'A1' => BigDecimal('26.0'),
            'B1' => BigDecimal('26.0'),
            'C1' => BigDecimal('26.0'),
            'D1' => BigDecimal('26.0')
          }
        end
        let(:expd_transfers) do
          {
            'A1' => { 'dest_locn' => 'A1', 'dest_conc' => '0.743' },
            'B1' => { 'dest_locn' => 'B1', 'dest_conc' => '0.743' },
            'C1' => { 'dest_locn' => 'C1', 'dest_conc' => '0.743' },
            'D1' => { 'dest_locn' => 'D1', 'dest_conc' => '0.743' }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers_hash(well_amounts, num_rows, num_cols)).to eq(expd_transfers)
        end
      end

      context 'when bins span multiple columns' do
        let(:well_amounts) do
          {
            'A1' => BigDecimal('1.0'),
            'B1' => BigDecimal('26.0'),
            'C1' => BigDecimal('501.0'),
            'D1' => BigDecimal('26.0'),
            'E1' => BigDecimal('26.0'),
            'F1' => BigDecimal('26.0'),
            'G1' => BigDecimal('26.0'),
            'H1' => BigDecimal('26.0'),
            'A2' => BigDecimal('26.0'),
            'B2' => BigDecimal('26.0'),
            'C2' => BigDecimal('26.0'),
            'D2' => BigDecimal('26.0'),
            'E2' => BigDecimal('26.0'),
            'F2' => BigDecimal('26.0'),
            'G2' => BigDecimal('26.0'),
            'H2' => BigDecimal('26.0'),
            'A3' => BigDecimal('26.0'),
            'B3' => BigDecimal('26.0'),
            'C3' => BigDecimal('26.0'),
            'D3' => BigDecimal('26.0'),
            'E3' => BigDecimal('26.0'),
            'F3' => BigDecimal('26.0')
          }
        end
        let(:expd_transfers) do
          {
            'A1' => { 'dest_locn' => 'A1', 'dest_conc' => '0.029' },
            'B1' => { 'dest_locn' => 'A2', 'dest_conc' => '0.743' },
            'C1' => { 'dest_locn' => 'A5', 'dest_conc' => '14.314' },
            'D1' => { 'dest_locn' => 'B2', 'dest_conc' => '0.743' },
            'E1' => { 'dest_locn' => 'C2', 'dest_conc' => '0.743' },
            'F1' => { 'dest_locn' => 'D2', 'dest_conc' => '0.743' },
            'G1' => { 'dest_locn' => 'E2', 'dest_conc' => '0.743' },
            'H1' => { 'dest_locn' => 'F2', 'dest_conc' => '0.743' },
            'A2' => { 'dest_locn' => 'G2', 'dest_conc' => '0.743' },
            'B2' => { 'dest_locn' => 'H2', 'dest_conc' => '0.743' },
            'C2' => { 'dest_locn' => 'A3', 'dest_conc' => '0.743' },
            'D2' => { 'dest_locn' => 'B3', 'dest_conc' => '0.743' },
            'E2' => { 'dest_locn' => 'C3', 'dest_conc' => '0.743' },
            'F2' => { 'dest_locn' => 'D3', 'dest_conc' => '0.743' },
            'G2' => { 'dest_locn' => 'E3', 'dest_conc' => '0.743' },
            'H2' => { 'dest_locn' => 'F3', 'dest_conc' => '0.743' },
            'A3' => { 'dest_locn' => 'G3', 'dest_conc' => '0.743' },
            'B3' => { 'dest_locn' => 'H3', 'dest_conc' => '0.743' },
            'C3' => { 'dest_locn' => 'A4', 'dest_conc' => '0.743' },
            'D3' => { 'dest_locn' => 'B4', 'dest_conc' => '0.743' },
            'E3' => { 'dest_locn' => 'C4', 'dest_conc' => '0.743' },
            'F3' => { 'dest_locn' => 'D4', 'dest_conc' => '0.743' }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers_hash(well_amounts, num_rows, num_cols)).to eq(expd_transfers)
        end
      end

      context 'when requiring compression due to numbers of wells' do
        let(:expd_transfers) do
          {
            'A1' => { 'dest_locn' => 'A1', 'dest_conc' => '0.029' },
            'B1' => { 'dest_locn' => 'B1', 'dest_conc' => '0.029' },
            'C1' => { 'dest_locn' => 'C1', 'dest_conc' => '0.029' },
            'D1' => { 'dest_locn' => 'D1', 'dest_conc' => '0.029' },
            'E1' => { 'dest_locn' => 'E1', 'dest_conc' => '0.029' },
            'F1' => { 'dest_locn' => 'F1', 'dest_conc' => '0.029' },
            'G1' => { 'dest_locn' => 'G1', 'dest_conc' => '0.029' },
            'H1' => { 'dest_locn' => 'H1', 'dest_conc' => '0.029' },
            'A2' => { 'dest_locn' => 'A2', 'dest_conc' => '0.029' },
            'B2' => { 'dest_locn' => 'B2', 'dest_conc' => '0.029' },
            'C2' => { 'dest_locn' => 'C2', 'dest_conc' => '0.029' },
            'D2' => { 'dest_locn' => 'D2', 'dest_conc' => '0.029' },
            'E2' => { 'dest_locn' => 'E2', 'dest_conc' => '0.029' },
            'F2' => { 'dest_locn' => 'F2', 'dest_conc' => '0.029' },
            'G2' => { 'dest_locn' => 'G2', 'dest_conc' => '0.029' },
            'H2' => { 'dest_locn' => 'H2', 'dest_conc' => '0.029' },
            'A3' => { 'dest_locn' => 'A3', 'dest_conc' => '0.029' },
            'B3' => { 'dest_locn' => 'B3', 'dest_conc' => '0.029' },
            'C3' => { 'dest_locn' => 'C3', 'dest_conc' => '0.029' },
            'D3' => { 'dest_locn' => 'D3', 'dest_conc' => '0.029' },
            'E3' => { 'dest_locn' => 'E3', 'dest_conc' => '0.029' },
            'F3' => { 'dest_locn' => 'F3', 'dest_conc' => '0.029' },
            'G3' => { 'dest_locn' => 'G3', 'dest_conc' => '0.029' },
            'H3' => { 'dest_locn' => 'H3', 'dest_conc' => '0.029' },
            'A4' => { 'dest_locn' => 'A4', 'dest_conc' => '0.029' },
            'B4' => { 'dest_locn' => 'B4', 'dest_conc' => '0.029' },
            'C4' => { 'dest_locn' => 'C4', 'dest_conc' => '0.029' },
            'D4' => { 'dest_locn' => 'D4', 'dest_conc' => '0.029' },
            'E4' => { 'dest_locn' => 'E4', 'dest_conc' => '0.029' },
            'F4' => { 'dest_locn' => 'F4', 'dest_conc' => '0.029' },
            'G4' => { 'dest_locn' => 'G4', 'dest_conc' => '0.029' },
            'H4' => { 'dest_locn' => 'H4', 'dest_conc' => '0.029' },
            'A5' => { 'dest_locn' => 'A5', 'dest_conc' => '0.029' },
            'B5' => { 'dest_locn' => 'B5', 'dest_conc' => '0.743' },
            'C5' => { 'dest_locn' => 'C5', 'dest_conc' => '0.743' },
            'D5' => { 'dest_locn' => 'D5', 'dest_conc' => '0.743' },
            'E5' => { 'dest_locn' => 'E5', 'dest_conc' => '0.743' },
            'F5' => { 'dest_locn' => 'F5', 'dest_conc' => '0.743' },
            'G5' => { 'dest_locn' => 'G5', 'dest_conc' => '0.743' },
            'H5' => { 'dest_locn' => 'H5', 'dest_conc' => '0.743' },
            'A6' => { 'dest_locn' => 'A6', 'dest_conc' => '0.743' },
            'B6' => { 'dest_locn' => 'B6', 'dest_conc' => '0.743' },
            'C6' => { 'dest_locn' => 'C6', 'dest_conc' => '0.743' },
            'D6' => { 'dest_locn' => 'D6', 'dest_conc' => '0.743' },
            'E6' => { 'dest_locn' => 'E6', 'dest_conc' => '0.743' },
            'F6' => { 'dest_locn' => 'F6', 'dest_conc' => '0.743' },
            'G6' => { 'dest_locn' => 'G6', 'dest_conc' => '0.743' },
            'H6' => { 'dest_locn' => 'H6', 'dest_conc' => '0.743' },
            'A7' => { 'dest_locn' => 'A7', 'dest_conc' => '0.743' },
            'B7' => { 'dest_locn' => 'B7', 'dest_conc' => '0.743' },
            'C7' => { 'dest_locn' => 'C7', 'dest_conc' => '0.743' },
            'D7' => { 'dest_locn' => 'D7', 'dest_conc' => '0.743' },
            'E7' => { 'dest_locn' => 'E7', 'dest_conc' => '0.743' },
            'F7' => { 'dest_locn' => 'F7', 'dest_conc' => '0.743' },
            'G7' => { 'dest_locn' => 'G7', 'dest_conc' => '0.743' },
            'H7' => { 'dest_locn' => 'H7', 'dest_conc' => '0.743' },
            'A8' => { 'dest_locn' => 'A8', 'dest_conc' => '0.743' },
            'B8' => { 'dest_locn' => 'B8', 'dest_conc' => '0.743' },
            'C8' => { 'dest_locn' => 'C8', 'dest_conc' => '0.743' },
            'D8' => { 'dest_locn' => 'D8', 'dest_conc' => '0.743' },
            'E8' => { 'dest_locn' => 'E8', 'dest_conc' => '0.743' },
            'F8' => { 'dest_locn' => 'F8', 'dest_conc' => '0.743' },
            'G8' => { 'dest_locn' => 'G8', 'dest_conc' => '0.743' },
            'H8' => { 'dest_locn' => 'H8', 'dest_conc' => '14.314' },
            'A9' => { 'dest_locn' => 'A9', 'dest_conc' => '14.314' },
            'B9' => { 'dest_locn' => 'B9', 'dest_conc' => '14.314' },
            'C9' => { 'dest_locn' => 'C9', 'dest_conc' => '14.314' },
            'D9' => { 'dest_locn' => 'D9', 'dest_conc' => '14.314' },
            'E9' => { 'dest_locn' => 'E9', 'dest_conc' => '14.314' },
            'F9' => { 'dest_locn' => 'F9', 'dest_conc' => '14.314' },
            'G9' => { 'dest_locn' => 'G9', 'dest_conc' => '14.314' },
            'H9' => { 'dest_locn' => 'H9', 'dest_conc' => '14.314' },
            'A10' => { 'dest_locn' => 'A10', 'dest_conc' => '14.314' },
            'B10' => { 'dest_locn' => 'B10', 'dest_conc' => '14.314' },
            'C10' => { 'dest_locn' => 'C10', 'dest_conc' => '14.314' },
            'D10' => { 'dest_locn' => 'D10', 'dest_conc' => '14.314' },
            'E10' => { 'dest_locn' => 'E10', 'dest_conc' => '14.314' },
            'F10' => { 'dest_locn' => 'F10', 'dest_conc' => '14.314' },
            'G10' => { 'dest_locn' => 'G10', 'dest_conc' => '14.314' },
            'H10' => { 'dest_locn' => 'H10', 'dest_conc' => '14.314' },
            'A11' => { 'dest_locn' => 'A11', 'dest_conc' => '14.314' },
            'B11' => { 'dest_locn' => 'B11', 'dest_conc' => '14.314' },
            'C11' => { 'dest_locn' => 'C11', 'dest_conc' => '14.314' },
            'D11' => { 'dest_locn' => 'D11', 'dest_conc' => '14.314' },
            'E11' => { 'dest_locn' => 'E11', 'dest_conc' => '14.314' },
            'F11' => { 'dest_locn' => 'F11', 'dest_conc' => '14.314' },
            'G11' => { 'dest_locn' => 'G11', 'dest_conc' => '14.314' },
            'H11' => { 'dest_locn' => 'H11', 'dest_conc' => '14.314' },
            'A12' => { 'dest_locn' => 'A12', 'dest_conc' => '14.314' },
            'B12' => { 'dest_locn' => 'B12', 'dest_conc' => '14.314' },
            'C12' => { 'dest_locn' => 'C12', 'dest_conc' => '14.314' },
            'D12' => { 'dest_locn' => 'D12', 'dest_conc' => '14.314' },
            'E12' => { 'dest_locn' => 'E12', 'dest_conc' => '14.314' },
            'F12' => { 'dest_locn' => 'F12', 'dest_conc' => '14.314' },
            'G12' => { 'dest_locn' => 'G12', 'dest_conc' => '14.314' },
            'H12' => { 'dest_locn' => 'H12', 'dest_conc' => '14.314' }
          }
        end
        let(:well_amounts) do
          {
            'A1' => BigDecimal('1.0'),
            'B1' => BigDecimal('1.0'),
            'C1' => BigDecimal('1.0'),
            'D1' => BigDecimal('1.0'),
            'E1' => BigDecimal('1.0'),
            'F1' => BigDecimal('1.0'),
            'G1' => BigDecimal('1.0'),
            'H1' => BigDecimal('1.0'),
            'A2' => BigDecimal('1.0'),
            'B2' => BigDecimal('1.0'),
            'C2' => BigDecimal('1.0'),
            'D2' => BigDecimal('1.0'),
            'E2' => BigDecimal('1.0'),
            'F2' => BigDecimal('1.0'),
            'G2' => BigDecimal('1.0'),
            'H2' => BigDecimal('1.0'),
            'A3' => BigDecimal('1.0'),
            'B3' => BigDecimal('1.0'),
            'C3' => BigDecimal('1.0'),
            'D3' => BigDecimal('1.0'),
            'E3' => BigDecimal('1.0'),
            'F3' => BigDecimal('1.0'),
            'G3' => BigDecimal('1.0'),
            'H3' => BigDecimal('1.0'),
            'A4' => BigDecimal('1.0'),
            'B4' => BigDecimal('1.0'),
            'C4' => BigDecimal('1.0'),
            'D4' => BigDecimal('1.0'),
            'E4' => BigDecimal('1.0'),
            'F4' => BigDecimal('1.0'),
            'G4' => BigDecimal('1.0'),
            'H4' => BigDecimal('1.0'),
            'A5' => BigDecimal('1.0'),
            'B5' => BigDecimal('26.0'),
            'C5' => BigDecimal('26.0'),
            'D5' => BigDecimal('26.0'),
            'E5' => BigDecimal('26.0'),
            'F5' => BigDecimal('26.0'),
            'G5' => BigDecimal('26.0'),
            'H5' => BigDecimal('26.0'),
            'A6' => BigDecimal('26.0'),
            'B6' => BigDecimal('26.0'),
            'C6' => BigDecimal('26.0'),
            'D6' => BigDecimal('26.0'),
            'E6' => BigDecimal('26.0'),
            'F6' => BigDecimal('26.0'),
            'G6' => BigDecimal('26.0'),
            'H6' => BigDecimal('26.0'),
            'A7' => BigDecimal('26.0'),
            'B7' => BigDecimal('26.0'),
            'C7' => BigDecimal('26.0'),
            'D7' => BigDecimal('26.0'),
            'E7' => BigDecimal('26.0'),
            'F7' => BigDecimal('26.0'),
            'G7' => BigDecimal('26.0'),
            'H7' => BigDecimal('26.0'),
            'A8' => BigDecimal('26.0'),
            'B8' => BigDecimal('26.0'),
            'C8' => BigDecimal('26.0'),
            'D8' => BigDecimal('26.0'),
            'E8' => BigDecimal('26.0'),
            'F8' => BigDecimal('26.0'),
            'G8' => BigDecimal('26.0'),
            'H8' => BigDecimal('501.0'),
            'A9' => BigDecimal('501.0'),
            'B9' => BigDecimal('501.0'),
            'C9' => BigDecimal('501.0'),
            'D9' => BigDecimal('501.0'),
            'E9' => BigDecimal('501.0'),
            'F9' => BigDecimal('501.0'),
            'G9' => BigDecimal('501.0'),
            'H9' => BigDecimal('501.0'),
            'A10' => BigDecimal('501.0'),
            'B10' => BigDecimal('501.0'),
            'C10' => BigDecimal('501.0'),
            'D10' => BigDecimal('501.0'),
            'E10' => BigDecimal('501.0'),
            'F10' => BigDecimal('501.0'),
            'G10' => BigDecimal('501.0'),
            'H10' => BigDecimal('501.0'),
            'A11' => BigDecimal('501.0'),
            'B11' => BigDecimal('501.0'),
            'C11' => BigDecimal('501.0'),
            'D11' => BigDecimal('501.0'),
            'E11' => BigDecimal('501.0'),
            'F11' => BigDecimal('501.0'),
            'G11' => BigDecimal('501.0'),
            'H11' => BigDecimal('501.0'),
            'A12' => BigDecimal('501.0'),
            'B12' => BigDecimal('501.0'),
            'C12' => BigDecimal('501.0'),
            'D12' => BigDecimal('501.0'),
            'E12' => BigDecimal('501.0'),
            'F12' => BigDecimal('501.0'),
            'G12' => BigDecimal('501.0'),
            'H12' => BigDecimal('501.0')
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers_hash(well_amounts, num_rows, num_cols)).to eq(expd_transfers)
        end
      end

      context 'with a large bin' do
        let(:dilutions_config) do
          {
            'source_volume' => 10,
            'diluent_volume' => 25,
            'bins' => [
              { 'colour' => 1, 'pcr_cycles' => 20, 'max' => 10 },
              { 'colour' => 2, 'pcr_cycles' => 19, 'min' => 10, 'max' => 20 },
              { 'colour' => 3, 'pcr_cycles' => 18, 'min' => 20, 'max' => 30 },
              { 'colour' => 4, 'pcr_cycles' => 17, 'min' => 30, 'max' => 40 },
              { 'colour' => 5, 'pcr_cycles' => 16, 'min' => 40, 'max' => 50 },
              { 'colour' => 6, 'pcr_cycles' => 15, 'min' => 50, 'max' => 60 },
              { 'colour' => 7, 'pcr_cycles' => 14, 'min' => 60, 'max' => 70 },
              { 'colour' => 8, 'pcr_cycles' => 13, 'min' => 70, 'max' => 80 },
              { 'colour' => 9, 'pcr_cycles' => 12, 'min' => 80, 'max' => 90 },
              { 'colour' => 10, 'pcr_cycles' => 11, 'min' => 90, 'max' => 100 },
              { 'colour' => 11, 'pcr_cycles' => 10, 'min' => 100, 'max' => 110 },
              { 'colour' => 12, 'pcr_cycles' => 9, 'min' => 110, 'max' => 120 },
              { 'colour' => 13, 'pcr_cycles' => 8, 'min' => 120 }
            ]
          }
        end
        let(:well_amounts) do
          {
            'A1' => BigDecimal('1.0'),
            'B1' => BigDecimal('11.0'),
            'C1' => BigDecimal('21.0'),
            'D1' => BigDecimal('31.0'),
            'E1' => BigDecimal('41.0'),
            'F1' => BigDecimal('51.0'),
            'G1' => BigDecimal('61.0'),
            'H1' => BigDecimal('71.0'),
            'A2' => BigDecimal('81.0'),
            'B2' => BigDecimal('91.0'),
            'C2' => BigDecimal('101.0'),
            'D2' => BigDecimal('111.0'),
            'E2' => BigDecimal('121.0')
          }
        end
        let(:expd_transfers) do
          {
            'A1' => { 'dest_locn' => 'A1', 'dest_conc' => '0.029' },
            'B1' => { 'dest_locn' => 'B1', 'dest_conc' => '0.314' },
            'C1' => { 'dest_locn' => 'C1', 'dest_conc' => '0.6' },
            'D1' => { 'dest_locn' => 'D1', 'dest_conc' => '0.886' },
            'E1' => { 'dest_locn' => 'E1', 'dest_conc' => '1.171' },
            'F1' => { 'dest_locn' => 'F1', 'dest_conc' => '1.457' },
            'G1' => { 'dest_locn' => 'G1', 'dest_conc' => '1.743' },
            'H1' => { 'dest_locn' => 'H1', 'dest_conc' => '2.029' },
            'A2' => { 'dest_locn' => 'A2', 'dest_conc' => '2.314' },
            'B2' => { 'dest_locn' => 'B2', 'dest_conc' => '2.6' },
            'C2' => { 'dest_locn' => 'C2', 'dest_conc' => '2.886' },
            'D2' => { 'dest_locn' => 'D2', 'dest_conc' => '3.171' },
            'E2' => { 'dest_locn' => 'E2', 'dest_conc' => '3.457' }
          }
        end

        it 'works when requiring compression when bins exceed plate columns' do
          expect(subject.compute_well_transfers_hash(well_amounts, num_rows, num_cols)).to eq(expd_transfers)
        end
      end
    end

    describe '#extract_destination_concentrations' do
      it_behaves_like 'it extracts destination concentrations'
    end

    describe '#construct_dest_qc_assay_attributes' do
      it_behaves_like 'it constructs destination qc assay attributes'
    end

    describe '#compute_presenter_bin_details' do
      context 'when generating presenter well bin details' do
        let(:well_a1) do
          create(:v2_well,
                 position: { 'name' => 'A1' },
                 qc_results: create_list(:qc_result_concentration, 1, value: 0.2))
        end
        let(:well_b1) do
          create(:v2_well,
                 position: { 'name' => 'B1' },
                 qc_results: create_list(:qc_result_concentration, 1, value: 56.0))
        end
        let(:well_c1) do
          create(:v2_well,
                 position: { 'name' => 'C1' },
                 qc_results: create_list(:qc_result_concentration, 1, value: 3.5))
        end
        let(:well_d1) do
          create(:v2_well,
                 position: { 'name' => 'D1' },
                 qc_results: create_list(:qc_result_concentration, 1, value: 0.7))
        end
        let(:child_plate) do
          create :v2_plate,
                 uuid: parent_uuid,
                 barcode_number: '3',
                 size: plate_size,
                 wells: [well_a1, well_b1, well_c1, well_d1],
                 outer_requests: requests
        end

        let(:expected_bin_details) do
          {
            'A1' => { 'colour' => 1, 'pcr_cycles' => 16 },
            'B1' => { 'colour' => 3, 'pcr_cycles' => 8 },
            'C1' => { 'colour' => 2, 'pcr_cycles' => 12 },
            'D1' => { 'colour' => 1, 'pcr_cycles' => 16 }
          }
        end

        it 'creates the correct well information' do
          expect(subject.compute_presenter_bin_details(child_plate)).to eq(expected_bin_details)
        end
      end
    end
  end
end
