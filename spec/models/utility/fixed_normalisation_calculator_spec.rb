# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/common_calculations_shared_examples'

RSpec.describe Utility::FixedNormalisationCalculator do
  context 'when computing values for fixed normalisation' do
    subject { described_class.new(dilutions_config) }

    let(:assay_version) { 'v1.0' }
    let(:parent_uuid) { 'example-plate-uuid' }
    let(:plate_size) { 96 }

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

    let(:dilutions_config) { { 'source_volume' => 2, 'diluent_volume' => 33 } }

    describe '#source_multiplication_factor' do
      it 'calculates value correctly' do
        expect(subject.source_multiplication_factor).to eq(2.0)
      end
    end

    describe '#dest_multiplication_factor' do
      it 'calculates value correctly' do
        expect(subject.dest_multiplication_factor).to eq(35.0)
      end
    end

    describe '#compute_well_amounts' do
      context 'for all wells in the parent plate' do
        let(:filtered_wells) { [well_a1, well_b1, well_c1, well_d1] }

        it 'calculates plate well amounts correctly' do
          expected_amounts = { 'A1' => 3.0, 'B1' => 112.0, 'C1' => 7.0, 'D1' => 3.6 }

          expect(subject.compute_well_amounts(filtered_wells)).to eq(expected_amounts)
        end
      end

      context 'for a partial submission' do
        let(:filtered_wells) { [well_b1, well_d1] }

        it 'calculates plate well amounts correctly' do
          expected_amounts = { 'B1' => 112.0, 'D1' => 3.6 }

          expect(subject.compute_well_amounts(filtered_wells)).to eq(expected_amounts)
        end
      end
    end

    describe '#compute_well_transfers' do
      context 'for all wells in the parent plate' do
        let(:filtered_wells) { [well_a1, well_b1, well_c1, well_d1] }

        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '0.08571428571428572'
            },
            'B1' => {
              'dest_locn' => 'B1',
              'dest_conc' => '3.2'
            },
            'C1' => {
              'dest_locn' => 'C1',
              'dest_conc' => '0.2'
            },
            'D1' => {
              'dest_locn' => 'D1',
              'dest_conc' => '0.10285714285714286'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate, filtered_wells)).to eq(expd_transfers)
          expect(subject.errors.messages.empty?).to be(true)
        end
      end

      context 'for a partial submission' do
        let(:filtered_wells) { [well_b1, well_d1] }

        # it should compress wells to top left by column
        let(:expd_transfers) do
          {
            'B1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '3.2'
            },
            'D1' => {
              'dest_locn' => 'B1',
              'dest_conc' => '0.10285714285714286'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate, filtered_wells)).to eq(expd_transfers)
          expect(subject.errors.messages.empty?).to be(true)
        end
      end
    end

    describe '#extract_destination_concentrations' do
      it_behaves_like 'it extracts destination concentrations'
    end

    describe '#construct_dest_qc_assay_attributes' do
      it_behaves_like 'it constructs destination qc assay attributes'
    end
  end
end
