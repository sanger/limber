# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/common_calculations_shared_examples'

RSpec.describe Utility::ConcentrationBinningCalculator do
  context 'when computing values for concentration binning' do
    subject { described_class.new(dilutions_config) }

    let(:assay_version) { 'v1.0' }
    let(:parent_uuid) { 'example-plate-uuid' }
    let(:plate_size) { 96 }
    let(:num_rows) { 8 }
    let(:num_cols) { 12 }

    let(:well_a1) do
      create(
        :well,
        position: {
          'name' => 'A1'
        },
        qc_results: create_list(:qc_result_concentration, 1, value: '1.5'),
        requests_as_source: [requests[0]]
      )
    end
    let(:well_b1) do
      create(
        :well,
        position: {
          'name' => 'B1'
        },
        qc_results: create_list(:qc_result_concentration, 1, value: '56.0'),
        requests_as_source: [requests[1]]
      )
    end
    let(:well_c1) do
      create(
        :well,
        position: {
          'name' => 'C1'
        },
        qc_results: create_list(:qc_result_concentration, 1, value: '3.5'),
        requests_as_source: [requests[2]]
      )
    end
    let(:well_d1) do
      create(
        :well,
        position: {
          'name' => 'D1'
        },
        qc_results: create_list(:qc_result_concentration, 1, value: '1.8'),
        requests_as_source: [requests[3]]
      )
    end

    let(:parent_plate) do
      create :plate,
             uuid: parent_uuid,
             barcode_number: '2',
             size: plate_size,
             wells: [well_a1, well_b1, well_c1, well_d1],
             outer_requests: requests
    end

    let(:library_type_name) { 'Test Library Type' }

    let(:requests) do
      Array.new(4) do |i|
        create :library_request, state: 'pending', uuid: "request-#{i}", library_type: library_type_name
      end
    end

    let(:dilutions_config) do
      {
        'source_volume' => 10,
        'diluent_volume' => 25,
        'bins' => [
          { 'colour' => 1, 'pcr_cycles' => 16, 'max' => 25 },
          { 'colour' => 2, 'pcr_cycles' => 12, 'min' => 26, 'max' => 499 },
          { 'colour' => 3, 'pcr_cycles' => 8, 'min' => 500 }
        ]
      }
    end

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
      context 'for all wells in the parent plate' do
        let(:filtered_wells) { [well_a1, well_b1, well_c1, well_d1] }

        it 'calculates plate well amounts correctly' do
          expected_amounts = { 'A1' => 15.0, 'B1' => 560.0, 'C1' => 35.0, 'D1' => 18.0 }

          expect(subject.compute_well_amounts(filtered_wells, subject.source_multiplication_factor)).to eq(
            expected_amounts
          )
        end
      end

      context 'for a partial submission' do
        let(:filtered_wells) { [well_b1, well_d1] }

        it 'calculates plate well amounts correctly' do
          expected_amounts = { 'B1' => 560.0, 'D1' => 18.0 }

          expect(subject.compute_well_amounts(filtered_wells, subject.source_multiplication_factor)).to eq(
            expected_amounts
          )
        end
      end
    end

    describe '#compute_well_transfers' do
      context 'for a simple example with few wells' do
        let(:filtered_wells) { [well_a1, well_b1, well_c1, well_d1] }

        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '0.42857142857142855'
            },
            'B1' => {
              'dest_locn' => 'A3',
              'dest_conc' => '16.0'
            },
            'C1' => {
              'dest_locn' => 'A2',
              'dest_conc' => '1.0'
            },
            'D1' => {
              'dest_locn' => 'B1',
              'dest_conc' => '0.5142857142857142'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate, filtered_wells)).to eq(expd_transfers)
        end
      end

      context 'for a partial submission' do
        let(:filtered_wells) { [well_b1, well_d1] }

        let(:expd_transfers) do
          {
            'B1' => {
              'dest_locn' => 'A2',
              'dest_conc' => '16.0'
            },
            'D1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '0.5142857142857142'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate, filtered_wells)).to eq(expd_transfers)
          expect(subject.errors.messages.empty?).to be(true)
        end
      end

      context 'when all wells fall in the same bin' do
        let(:filtered_wells) { [well_a1, well_b1, well_c1, well_d1] }

        let(:well_a1) do
          create(
            :well,
            position: {
              'name' => 'A1'
            },
            qc_results: create_list(:qc_result_concentration, 1, value: '3.5'),
            requests_as_source: [requests[0]]
          )
        end
        let(:well_b1) do
          create(
            :well,
            position: {
              'name' => 'B1'
            },
            qc_results: create_list(:qc_result_concentration, 1, value: '3.5'),
            requests_as_source: [requests[1]]
          )
        end
        let(:well_d1) do
          create(
            :well,
            position: {
              'name' => 'D1'
            },
            qc_results: create_list(:qc_result_concentration, 1, value: '3.5'),
            requests_as_source: [requests[3]]
          )
        end
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '1.0'
            },
            'B1' => {
              'dest_locn' => 'B1',
              'dest_conc' => '1.0'
            },
            'C1' => {
              'dest_locn' => 'C1',
              'dest_conc' => '1.0'
            },
            'D1' => {
              'dest_locn' => 'D1',
              'dest_conc' => '1.0'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate, filtered_wells)).to eq(expd_transfers)
          expect(subject.errors.messages.empty?).to be(true)
        end
      end
    end

    describe '#compute_well_transfers_hash' do
      context 'for a simple example with few wells' do
        let(:well_amounts) { { 'A1' => 15.0, 'B1' => 560.0, 'C1' => 35.0, 'D1' => 18.0 } }
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '0.42857142857142855'
            },
            'B1' => {
              'dest_locn' => 'A3',
              'dest_conc' => '16.0'
            },
            'C1' => {
              'dest_locn' => 'A2',
              'dest_conc' => '1.0'
            },
            'D1' => {
              'dest_locn' => 'B1',
              'dest_conc' => '0.5142857142857142'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers_hash(well_amounts, num_rows, num_cols)).to eq(expd_transfers)
        end
      end

      context 'when all wells fall in the same bin' do
        let(:well_amounts) { { 'A1' => 26.0, 'B1' => 26.0, 'C1' => 26.0, 'D1' => 26.0 } }
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '0.7428571428571429'
            },
            'B1' => {
              'dest_locn' => 'B1',
              'dest_conc' => '0.7428571428571429'
            },
            'C1' => {
              'dest_locn' => 'C1',
              'dest_conc' => '0.7428571428571429'
            },
            'D1' => {
              'dest_locn' => 'D1',
              'dest_conc' => '0.7428571428571429'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers_hash(well_amounts, num_rows, num_cols)).to eq(expd_transfers)
        end
      end

      context 'when bins span multiple columns' do
        let(:well_amounts) do
          {
            'A1' => 1.0,
            'B1' => 26.0,
            'C1' => 501.0,
            'D1' => 26.0,
            'E1' => 26.0,
            'F1' => 26.0,
            'G1' => 26.0,
            'H1' => 26.0,
            'A2' => 26.0,
            'B2' => 26.0,
            'C2' => 26.0,
            'D2' => 26.0,
            'E2' => 26.0,
            'F2' => 26.0,
            'G2' => 26.0,
            'H2' => 26.0,
            'A3' => 26.0,
            'B3' => 26.0,
            'C3' => 26.0,
            'D3' => 26.0,
            'E3' => 26.0,
            'F3' => 26.0
          }
        end
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '0.02857142857142857'
            },
            'B1' => {
              'dest_locn' => 'A2',
              'dest_conc' => '0.7428571428571429'
            },
            'C1' => {
              'dest_locn' => 'A5',
              'dest_conc' => '14.314285714285715'
            },
            'D1' => {
              'dest_locn' => 'B2',
              'dest_conc' => '0.7428571428571429'
            },
            'E1' => {
              'dest_locn' => 'C2',
              'dest_conc' => '0.7428571428571429'
            },
            'F1' => {
              'dest_locn' => 'D2',
              'dest_conc' => '0.7428571428571429'
            },
            'G1' => {
              'dest_locn' => 'E2',
              'dest_conc' => '0.7428571428571429'
            },
            'H1' => {
              'dest_locn' => 'F2',
              'dest_conc' => '0.7428571428571429'
            },
            'A2' => {
              'dest_locn' => 'G2',
              'dest_conc' => '0.7428571428571429'
            },
            'B2' => {
              'dest_locn' => 'H2',
              'dest_conc' => '0.7428571428571429'
            },
            'C2' => {
              'dest_locn' => 'A3',
              'dest_conc' => '0.7428571428571429'
            },
            'D2' => {
              'dest_locn' => 'B3',
              'dest_conc' => '0.7428571428571429'
            },
            'E2' => {
              'dest_locn' => 'C3',
              'dest_conc' => '0.7428571428571429'
            },
            'F2' => {
              'dest_locn' => 'D3',
              'dest_conc' => '0.7428571428571429'
            },
            'G2' => {
              'dest_locn' => 'E3',
              'dest_conc' => '0.7428571428571429'
            },
            'H2' => {
              'dest_locn' => 'F3',
              'dest_conc' => '0.7428571428571429'
            },
            'A3' => {
              'dest_locn' => 'G3',
              'dest_conc' => '0.7428571428571429'
            },
            'B3' => {
              'dest_locn' => 'H3',
              'dest_conc' => '0.7428571428571429'
            },
            'C3' => {
              'dest_locn' => 'A4',
              'dest_conc' => '0.7428571428571429'
            },
            'D3' => {
              'dest_locn' => 'B4',
              'dest_conc' => '0.7428571428571429'
            },
            'E3' => {
              'dest_locn' => 'C4',
              'dest_conc' => '0.7428571428571429'
            },
            'F3' => {
              'dest_locn' => 'D4',
              'dest_conc' => '0.7428571428571429'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers_hash(well_amounts, num_rows, num_cols)).to eq(expd_transfers)
        end
      end

      context 'when bins span complete columns' do
        let(:well_amounts) do
          {
            'A1' => 501.0,
            'B1' => 501.0,
            'C1' => 501.0,
            'D1' => 501.0,
            'E1' => 501.0,
            'F1' => 501.0,
            'G1' => 501.0,
            'H1' => 501.0,
            'A2' => 26.0,
            'B2' => 26.0,
            'C2' => 26.0,
            'D2' => 26.0,
            'E2' => 26.0,
            'F2' => 26.0,
            'G2' => 26.0,
            'H2' => 26.0,
            'A3' => 1.0,
            'B3' => 1.0,
            'C3' => 1.0,
            'D3' => 1.0,
            'E3' => 1.0,
            'F3' => 1.0,
            'G3' => 1.0,
            'H3' => 1.0
          }
        end
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A3',
              'dest_conc' => '14.314285714285715'
            },
            'B1' => {
              'dest_locn' => 'B3',
              'dest_conc' => '14.314285714285715'
            },
            'C1' => {
              'dest_locn' => 'C3',
              'dest_conc' => '14.314285714285715'
            },
            'D1' => {
              'dest_locn' => 'D3',
              'dest_conc' => '14.314285714285715'
            },
            'E1' => {
              'dest_locn' => 'E3',
              'dest_conc' => '14.314285714285715'
            },
            'F1' => {
              'dest_locn' => 'F3',
              'dest_conc' => '14.314285714285715'
            },
            'G1' => {
              'dest_locn' => 'G3',
              'dest_conc' => '14.314285714285715'
            },
            'H1' => {
              'dest_locn' => 'H3',
              'dest_conc' => '14.314285714285715'
            },
            'A2' => {
              'dest_locn' => 'A2',
              'dest_conc' => '0.7428571428571429'
            },
            'B2' => {
              'dest_locn' => 'B2',
              'dest_conc' => '0.7428571428571429'
            },
            'C2' => {
              'dest_locn' => 'C2',
              'dest_conc' => '0.7428571428571429'
            },
            'D2' => {
              'dest_locn' => 'D2',
              'dest_conc' => '0.7428571428571429'
            },
            'E2' => {
              'dest_locn' => 'E2',
              'dest_conc' => '0.7428571428571429'
            },
            'F2' => {
              'dest_locn' => 'F2',
              'dest_conc' => '0.7428571428571429'
            },
            'G2' => {
              'dest_locn' => 'G2',
              'dest_conc' => '0.7428571428571429'
            },
            'H2' => {
              'dest_locn' => 'H2',
              'dest_conc' => '0.7428571428571429'
            },
            'A3' => {
              'dest_locn' => 'A1',
              'dest_conc' => '0.02857142857142857'
            },
            'B3' => {
              'dest_locn' => 'B1',
              'dest_conc' => '0.02857142857142857'
            },
            'C3' => {
              'dest_locn' => 'C1',
              'dest_conc' => '0.02857142857142857'
            },
            'D3' => {
              'dest_locn' => 'D1',
              'dest_conc' => '0.02857142857142857'
            },
            'E3' => {
              'dest_locn' => 'E1',
              'dest_conc' => '0.02857142857142857'
            },
            'F3' => {
              'dest_locn' => 'F1',
              'dest_conc' => '0.02857142857142857'
            },
            'G3' => {
              'dest_locn' => 'G1',
              'dest_conc' => '0.02857142857142857'
            },
            'H3' => {
              'dest_locn' => 'H1',
              'dest_conc' => '0.02857142857142857'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers_hash(well_amounts, num_rows, num_cols)).to eq(expd_transfers)
        end
      end

      context 'when requiring compression due to numbers of wells' do
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '0.02857142857142857'
            },
            'B1' => {
              'dest_locn' => 'B1',
              'dest_conc' => '0.02857142857142857'
            },
            'C1' => {
              'dest_locn' => 'C1',
              'dest_conc' => '0.02857142857142857'
            },
            'D1' => {
              'dest_locn' => 'D1',
              'dest_conc' => '0.02857142857142857'
            },
            'E1' => {
              'dest_locn' => 'E1',
              'dest_conc' => '0.02857142857142857'
            },
            'F1' => {
              'dest_locn' => 'F1',
              'dest_conc' => '0.02857142857142857'
            },
            'G1' => {
              'dest_locn' => 'G1',
              'dest_conc' => '0.02857142857142857'
            },
            'H1' => {
              'dest_locn' => 'H1',
              'dest_conc' => '0.02857142857142857'
            },
            'A2' => {
              'dest_locn' => 'A2',
              'dest_conc' => '0.02857142857142857'
            },
            'B2' => {
              'dest_locn' => 'B2',
              'dest_conc' => '0.02857142857142857'
            },
            'C2' => {
              'dest_locn' => 'C2',
              'dest_conc' => '0.02857142857142857'
            },
            'D2' => {
              'dest_locn' => 'D2',
              'dest_conc' => '0.02857142857142857'
            },
            'E2' => {
              'dest_locn' => 'E2',
              'dest_conc' => '0.02857142857142857'
            },
            'F2' => {
              'dest_locn' => 'F2',
              'dest_conc' => '0.02857142857142857'
            },
            'G2' => {
              'dest_locn' => 'G2',
              'dest_conc' => '0.02857142857142857'
            },
            'H2' => {
              'dest_locn' => 'H2',
              'dest_conc' => '0.02857142857142857'
            },
            'A3' => {
              'dest_locn' => 'A3',
              'dest_conc' => '0.02857142857142857'
            },
            'B3' => {
              'dest_locn' => 'B3',
              'dest_conc' => '0.02857142857142857'
            },
            'C3' => {
              'dest_locn' => 'C3',
              'dest_conc' => '0.02857142857142857'
            },
            'D3' => {
              'dest_locn' => 'D3',
              'dest_conc' => '0.02857142857142857'
            },
            'E3' => {
              'dest_locn' => 'E3',
              'dest_conc' => '0.02857142857142857'
            },
            'F3' => {
              'dest_locn' => 'F3',
              'dest_conc' => '0.02857142857142857'
            },
            'G3' => {
              'dest_locn' => 'G3',
              'dest_conc' => '0.02857142857142857'
            },
            'H3' => {
              'dest_locn' => 'H3',
              'dest_conc' => '0.02857142857142857'
            },
            'A4' => {
              'dest_locn' => 'A4',
              'dest_conc' => '0.02857142857142857'
            },
            'B4' => {
              'dest_locn' => 'B4',
              'dest_conc' => '0.02857142857142857'
            },
            'C4' => {
              'dest_locn' => 'C4',
              'dest_conc' => '0.02857142857142857'
            },
            'D4' => {
              'dest_locn' => 'D4',
              'dest_conc' => '0.02857142857142857'
            },
            'E4' => {
              'dest_locn' => 'E4',
              'dest_conc' => '0.02857142857142857'
            },
            'F4' => {
              'dest_locn' => 'F4',
              'dest_conc' => '0.02857142857142857'
            },
            'G4' => {
              'dest_locn' => 'G4',
              'dest_conc' => '0.02857142857142857'
            },
            'H4' => {
              'dest_locn' => 'H4',
              'dest_conc' => '0.02857142857142857'
            },
            'A5' => {
              'dest_locn' => 'A5',
              'dest_conc' => '0.02857142857142857'
            },
            'B5' => {
              'dest_locn' => 'B5',
              'dest_conc' => '0.7428571428571429'
            },
            'C5' => {
              'dest_locn' => 'C5',
              'dest_conc' => '0.7428571428571429'
            },
            'D5' => {
              'dest_locn' => 'D5',
              'dest_conc' => '0.7428571428571429'
            },
            'E5' => {
              'dest_locn' => 'E5',
              'dest_conc' => '0.7428571428571429'
            },
            'F5' => {
              'dest_locn' => 'F5',
              'dest_conc' => '0.7428571428571429'
            },
            'G5' => {
              'dest_locn' => 'G5',
              'dest_conc' => '0.7428571428571429'
            },
            'H5' => {
              'dest_locn' => 'H5',
              'dest_conc' => '0.7428571428571429'
            },
            'A6' => {
              'dest_locn' => 'A6',
              'dest_conc' => '0.7428571428571429'
            },
            'B6' => {
              'dest_locn' => 'B6',
              'dest_conc' => '0.7428571428571429'
            },
            'C6' => {
              'dest_locn' => 'C6',
              'dest_conc' => '0.7428571428571429'
            },
            'D6' => {
              'dest_locn' => 'D6',
              'dest_conc' => '0.7428571428571429'
            },
            'E6' => {
              'dest_locn' => 'E6',
              'dest_conc' => '0.7428571428571429'
            },
            'F6' => {
              'dest_locn' => 'F6',
              'dest_conc' => '0.7428571428571429'
            },
            'G6' => {
              'dest_locn' => 'G6',
              'dest_conc' => '0.7428571428571429'
            },
            'H6' => {
              'dest_locn' => 'H6',
              'dest_conc' => '0.7428571428571429'
            },
            'A7' => {
              'dest_locn' => 'A7',
              'dest_conc' => '0.7428571428571429'
            },
            'B7' => {
              'dest_locn' => 'B7',
              'dest_conc' => '0.7428571428571429'
            },
            'C7' => {
              'dest_locn' => 'C7',
              'dest_conc' => '0.7428571428571429'
            },
            'D7' => {
              'dest_locn' => 'D7',
              'dest_conc' => '0.7428571428571429'
            },
            'E7' => {
              'dest_locn' => 'E7',
              'dest_conc' => '0.7428571428571429'
            },
            'F7' => {
              'dest_locn' => 'F7',
              'dest_conc' => '0.7428571428571429'
            },
            'G7' => {
              'dest_locn' => 'G7',
              'dest_conc' => '0.7428571428571429'
            },
            'H7' => {
              'dest_locn' => 'H7',
              'dest_conc' => '0.7428571428571429'
            },
            'A8' => {
              'dest_locn' => 'A8',
              'dest_conc' => '0.7428571428571429'
            },
            'B8' => {
              'dest_locn' => 'B8',
              'dest_conc' => '0.7428571428571429'
            },
            'C8' => {
              'dest_locn' => 'C8',
              'dest_conc' => '0.7428571428571429'
            },
            'D8' => {
              'dest_locn' => 'D8',
              'dest_conc' => '0.7428571428571429'
            },
            'E8' => {
              'dest_locn' => 'E8',
              'dest_conc' => '0.7428571428571429'
            },
            'F8' => {
              'dest_locn' => 'F8',
              'dest_conc' => '0.7428571428571429'
            },
            'G8' => {
              'dest_locn' => 'G8',
              'dest_conc' => '0.7428571428571429'
            },
            'H8' => {
              'dest_locn' => 'H8',
              'dest_conc' => '14.314285714285715'
            },
            'A9' => {
              'dest_locn' => 'A9',
              'dest_conc' => '14.314285714285715'
            },
            'B9' => {
              'dest_locn' => 'B9',
              'dest_conc' => '14.314285714285715'
            },
            'C9' => {
              'dest_locn' => 'C9',
              'dest_conc' => '14.314285714285715'
            },
            'D9' => {
              'dest_locn' => 'D9',
              'dest_conc' => '14.314285714285715'
            },
            'E9' => {
              'dest_locn' => 'E9',
              'dest_conc' => '14.314285714285715'
            },
            'F9' => {
              'dest_locn' => 'F9',
              'dest_conc' => '14.314285714285715'
            },
            'G9' => {
              'dest_locn' => 'G9',
              'dest_conc' => '14.314285714285715'
            },
            'H9' => {
              'dest_locn' => 'H9',
              'dest_conc' => '14.314285714285715'
            },
            'A10' => {
              'dest_locn' => 'A10',
              'dest_conc' => '14.314285714285715'
            },
            'B10' => {
              'dest_locn' => 'B10',
              'dest_conc' => '14.314285714285715'
            },
            'C10' => {
              'dest_locn' => 'C10',
              'dest_conc' => '14.314285714285715'
            },
            'D10' => {
              'dest_locn' => 'D10',
              'dest_conc' => '14.314285714285715'
            },
            'E10' => {
              'dest_locn' => 'E10',
              'dest_conc' => '14.314285714285715'
            },
            'F10' => {
              'dest_locn' => 'F10',
              'dest_conc' => '14.314285714285715'
            },
            'G10' => {
              'dest_locn' => 'G10',
              'dest_conc' => '14.314285714285715'
            },
            'H10' => {
              'dest_locn' => 'H10',
              'dest_conc' => '14.314285714285715'
            },
            'A11' => {
              'dest_locn' => 'A11',
              'dest_conc' => '14.314285714285715'
            },
            'B11' => {
              'dest_locn' => 'B11',
              'dest_conc' => '14.314285714285715'
            },
            'C11' => {
              'dest_locn' => 'C11',
              'dest_conc' => '14.314285714285715'
            },
            'D11' => {
              'dest_locn' => 'D11',
              'dest_conc' => '14.314285714285715'
            },
            'E11' => {
              'dest_locn' => 'E11',
              'dest_conc' => '14.314285714285715'
            },
            'F11' => {
              'dest_locn' => 'F11',
              'dest_conc' => '14.314285714285715'
            },
            'G11' => {
              'dest_locn' => 'G11',
              'dest_conc' => '14.314285714285715'
            },
            'H11' => {
              'dest_locn' => 'H11',
              'dest_conc' => '14.314285714285715'
            },
            'A12' => {
              'dest_locn' => 'A12',
              'dest_conc' => '14.314285714285715'
            },
            'B12' => {
              'dest_locn' => 'B12',
              'dest_conc' => '14.314285714285715'
            },
            'C12' => {
              'dest_locn' => 'C12',
              'dest_conc' => '14.314285714285715'
            },
            'D12' => {
              'dest_locn' => 'D12',
              'dest_conc' => '14.314285714285715'
            },
            'E12' => {
              'dest_locn' => 'E12',
              'dest_conc' => '14.314285714285715'
            },
            'F12' => {
              'dest_locn' => 'F12',
              'dest_conc' => '14.314285714285715'
            },
            'G12' => {
              'dest_locn' => 'G12',
              'dest_conc' => '14.314285714285715'
            },
            'H12' => {
              'dest_locn' => 'H12',
              'dest_conc' => '14.314285714285715'
            }
          }
        end
        let(:well_amounts) do
          {
            'A1' => 1.0,
            'B1' => 1.0,
            'C1' => 1.0,
            'D1' => 1.0,
            'E1' => 1.0,
            'F1' => 1.0,
            'G1' => 1.0,
            'H1' => 1.0,
            'A2' => 1.0,
            'B2' => 1.0,
            'C2' => 1.0,
            'D2' => 1.0,
            'E2' => 1.0,
            'F2' => 1.0,
            'G2' => 1.0,
            'H2' => 1.0,
            'A3' => 1.0,
            'B3' => 1.0,
            'C3' => 1.0,
            'D3' => 1.0,
            'E3' => 1.0,
            'F3' => 1.0,
            'G3' => 1.0,
            'H3' => 1.0,
            'A4' => 1.0,
            'B4' => 1.0,
            'C4' => 1.0,
            'D4' => 1.0,
            'E4' => 1.0,
            'F4' => 1.0,
            'G4' => 1.0,
            'H4' => 1.0,
            'A5' => 1.0,
            'B5' => 26.0,
            'C5' => 26.0,
            'D5' => 26.0,
            'E5' => 26.0,
            'F5' => 26.0,
            'G5' => 26.0,
            'H5' => 26.0,
            'A6' => 26.0,
            'B6' => 26.0,
            'C6' => 26.0,
            'D6' => 26.0,
            'E6' => 26.0,
            'F6' => 26.0,
            'G6' => 26.0,
            'H6' => 26.0,
            'A7' => 26.0,
            'B7' => 26.0,
            'C7' => 26.0,
            'D7' => 26.0,
            'E7' => 26.0,
            'F7' => 26.0,
            'G7' => 26.0,
            'H7' => 26.0,
            'A8' => 26.0,
            'B8' => 26.0,
            'C8' => 26.0,
            'D8' => 26.0,
            'E8' => 26.0,
            'F8' => 26.0,
            'G8' => 26.0,
            'H8' => 501.0,
            'A9' => 501.0,
            'B9' => 501.0,
            'C9' => 501.0,
            'D9' => 501.0,
            'E9' => 501.0,
            'F9' => 501.0,
            'G9' => 501.0,
            'H9' => 501.0,
            'A10' => 501.0,
            'B10' => 501.0,
            'C10' => 501.0,
            'D10' => 501.0,
            'E10' => 501.0,
            'F10' => 501.0,
            'G10' => 501.0,
            'H10' => 501.0,
            'A11' => 501.0,
            'B11' => 501.0,
            'C11' => 501.0,
            'D11' => 501.0,
            'E11' => 501.0,
            'F11' => 501.0,
            'G11' => 501.0,
            'H11' => 501.0,
            'A12' => 501.0,
            'B12' => 501.0,
            'C12' => 501.0,
            'D12' => 501.0,
            'E12' => 501.0,
            'F12' => 501.0,
            'G12' => 501.0,
            'H12' => 501.0
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers_hash(well_amounts, num_rows, num_cols)).to eq(expd_transfers)
        end
      end

      context 'with a large number of bins' do
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
            'A1' => 1.0,
            'B1' => 11.0,
            'C1' => 21.0,
            'D1' => 31.0,
            'E1' => 41.0,
            'F1' => 51.0,
            'G1' => 61.0,
            'H1' => 71.0,
            'A2' => 81.0,
            'B2' => 91.0,
            'C2' => 101.0,
            'D2' => 111.0,
            'E2' => 121.0
          }
        end
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '0.02857142857142857'
            },
            'B1' => {
              'dest_locn' => 'B1',
              'dest_conc' => '0.3142857142857143'
            },
            'C1' => {
              'dest_locn' => 'C1',
              'dest_conc' => '0.6'
            },
            'D1' => {
              'dest_locn' => 'D1',
              'dest_conc' => '0.8857142857142857'
            },
            'E1' => {
              'dest_locn' => 'E1',
              'dest_conc' => '1.1714285714285715'
            },
            'F1' => {
              'dest_locn' => 'F1',
              'dest_conc' => '1.457142857142857'
            },
            'G1' => {
              'dest_locn' => 'G1',
              'dest_conc' => '1.7428571428571429'
            },
            'H1' => {
              'dest_locn' => 'H1',
              'dest_conc' => '2.0285714285714285'
            },
            'A2' => {
              'dest_locn' => 'A2',
              'dest_conc' => '2.3142857142857145'
            },
            'B2' => {
              'dest_locn' => 'B2',
              'dest_conc' => '2.6'
            },
            'C2' => {
              'dest_locn' => 'C2',
              'dest_conc' => '2.8857142857142857'
            },
            'D2' => {
              'dest_locn' => 'D2',
              'dest_conc' => '3.1714285714285713'
            },
            'E2' => {
              'dest_locn' => 'E2',
              'dest_conc' => '3.4571428571428573'
            }
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
          create(
            :well,
            position: {
              'name' => 'A1'
            },
            qc_results: create_list(:qc_result_concentration, 1, value: '0.2'),
            requests_as_source: [requests[0]]
          )
        end
        let(:well_b1) do
          create(
            :well,
            position: {
              'name' => 'B1'
            },
            qc_results: create_list(:qc_result_concentration, 1, value: '56.0'),
            requests_as_source: [requests[1]]
          )
        end
        let(:well_c1) do
          create(
            :well,
            position: {
              'name' => 'C1'
            },
            qc_results: create_list(:qc_result_concentration, 1, value: '3.5'),
            requests_as_source: [requests[2]]
          )
        end
        let(:well_d1) do
          create(
            :well,
            position: {
              'name' => 'D1'
            },
            qc_results: create_list(:qc_result_concentration, 1, value: '0.7'),
            requests_as_source: [requests[3]]
          )
        end
        let(:child_plate) do
          create :plate,
                 uuid: parent_uuid,
                 barcode_number: '3',
                 size: plate_size,
                 wells: [well_a1, well_b1, well_c1, well_d1],
                 outer_requests: requests
        end

        let(:expected_bin_details) do
          {
            'A1' => {
              'colour' => 1,
              'pcr_cycles' => 16
            },
            'B1' => {
              'colour' => 3,
              'pcr_cycles' => 8
            },
            'C1' => {
              'colour' => 2,
              'pcr_cycles' => 12
            },
            'D1' => {
              'colour' => 1,
              'pcr_cycles' => 16
            }
          }
        end

        it 'creates the correct well information' do
          expect(subject.compute_presenter_bin_details(child_plate)).to eq(expected_bin_details)
        end
      end
    end
  end
end

RSpec.describe Utility::ConcentrationBinningCalculator::Binner do
  context 'when calculating binned well locations' do
    it_behaves_like 'it throws exceptions from binner class'
  end
end
