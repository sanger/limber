# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/common_calculations_shared_examples'

RSpec.describe Utility::ConcentrationNormalisationCalculator do
  context 'when computing values for normalised binning' do
    subject { described_class.new(dilutions_config) }

    let(:assay_version) { 'v1.0' }
    let(:parent_uuid) { 'example-plate-uuid' }
    let(:plate_size) { 96 }

    let(:well_a1) do
      create(:v2_well, position: { 'name' => 'A1' }, qc_results: create_list(:qc_result_concentration, 1, value: '1.0'))
    end
    let(:well_b1) do
      create(
        :v2_well,
        position: {
          'name' => 'B1'
        },
        qc_results: create_list(:qc_result_concentration, 1, value: '56.0')
      )
    end
    let(:well_c1) do
      create(:v2_well, position: { 'name' => 'C1' }, qc_results: create_list(:qc_result_concentration, 1, value: '3.5'))
    end
    let(:well_d1) do
      create(:v2_well, position: { 'name' => 'D1' }, qc_results: create_list(:qc_result_concentration, 1, value: '1.8'))
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

    let(:dilutions_config) { { 'target_amount_ng' => 50, 'target_volume' => 20, 'minimum_source_volume' => 0.2 } }

    describe '#normalisation_details' do
      it 'calculates normalisation details correctly' do
        expected_norm_details = {
          'A1' => {
            'vol_source_reqd' => 20.0,
            'vol_diluent_reqd' => 0.0,
            'amount_in_target' => 20.0,
            'dest_conc' => 1.0
          },
          'B1' => {
            'vol_source_reqd' => 0.893,
            'vol_diluent_reqd' => 19.107,
            'amount_in_target' => 50.0,
            'dest_conc' => 2.5
          },
          'C1' => {
            'vol_source_reqd' => 14.286,
            'vol_diluent_reqd' => 5.714,
            'amount_in_target' => 50.0,
            'dest_conc' => 2.5
          },
          'D1' => {
            'vol_source_reqd' => 20.0,
            'vol_diluent_reqd' => 0.0,
            'amount_in_target' => 36.0,
            'dest_conc' => 1.8
          }
        }

        expect(subject.normalisation_details(parent_plate.wells)).to eq(expected_norm_details)
      end
    end

    describe '#compute_vol_source_reqd' do
      context 'when sample concentration is within range' do
        let(:sample_conc) { 50.0 }

        it 'returns expected volume' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(1.0)
        end
      end

      context 'when sample concentration is zero' do
        let(:sample_conc) { 0.0 }

        it 'returns the maximum volume' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(20.0)
        end
      end

      context 'when sample concentration is below range minimum' do
        let(:sample_conc) { 2.0 }

        it 'returns the maximum volume' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(20.0)
        end
      end

      context 'when sample concentration is above range maximum' do
        let(:sample_conc) { 500.0 }

        it 'returns the minimum volume' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(0.2)
        end
      end

      # conc would create a diluent vol of 0.1
      context 'when sample concentration would create a diluent volume of less than 0.5' do
        let(:sample_conc) { 2.5126 }

        it 'rounds up the sample volume to the maximum and takes zero diluent' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(20.0)
        end
      end

      # conc would create a diluent vol of 0.5
      context 'when sample concentration would create a diluent volume of exactly 0.5' do
        let(:sample_conc) { 2.5641 }

        it 'rounds up the sample volume to the maximum and takes zero diluent' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(20.0)
        end
      end

      # conc would create a diluent vol of 0.6
      context 'when sample concentration would create a diluent volume of 0.6' do
        let(:sample_conc) { 2.5773 }

        it 'rounds down the sample volume and takes the minimum diluent of 1' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(19.0)
        end
      end

      # conc would create a diluent vol of 0.9
      context 'when sample concentration would create a diluent volume of greater than 0.5 but less than 1.0' do
        let(:sample_conc) { 2.6178 }

        it 'rounds down the sample volume and takes the minimum diluent of 1' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(19.0)
        end
      end

      context 'when sample concentration would create a diluent volume greater than 1' do
        let(:sample_conc) { 3.120 }

        it 'does not round the sample volume required' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(16.025641025641026)
        end
      end
    end

    describe '#compute_well_transfers' do
      context 'for a simple example with few wells' do
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'dest_conc' => '1.0',
              'volume' => '20.0'
            },
            'B1' => {
              'dest_locn' => 'B1',
              'dest_conc' => '2.5',
              'volume' => '0.893'
            },
            'C1' => {
              'dest_locn' => 'C1',
              'dest_conc' => '2.5',
              'volume' => '14.286'
            },
            'D1' => {
              'dest_locn' => 'D1',
              'dest_conc' => '1.8',
              'volume' => '20.0'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate)).to eq(expd_transfers)
          expect(subject.errors.messages.empty?).to be(true)
        end
      end
    end

    describe '#extract_destination_concentrations' do
      let(:transfer_hash) do
        {
          'A1' => {
            'dest_locn' => 'A1',
            'dest_conc' => '0.665'
          },
          'B1' => {
            'dest_locn' => 'B1',
            'dest_conc' => '0.343'
          },
          'C1' => {
            'dest_locn' => 'C1',
            'dest_conc' => '2.135'
          },
          'D1' => {
            'dest_locn' => 'D1',
            'dest_conc' => '3.123'
          },
          'E1' => {
            'dest_locn' => 'E1',
            'dest_conc' => '3.045'
          },
          'F1' => {
            'dest_locn' => 'F1',
            'dest_conc' => '0.743'
          },
          'G1' => {
            'dest_locn' => 'G1',
            'dest_conc' => '0.693'
          }
        }
      end
      let(:expected_dest_concs) do
        {
          'A1' => '0.665',
          'B1' => '0.343',
          'C1' => '2.135',
          'D1' => '3.123',
          'E1' => '3.045',
          'F1' => '0.743',
          'G1' => '0.693'
        }
      end

      it 'refactors the transfers hash correctly' do
        expect(subject.extract_destination_concentrations(transfer_hash)).to eq(expected_dest_concs)
      end
    end

    describe '#construct_dest_qc_assay_attributes' do
      let(:transfer_hash) do
        {
          'A1' => {
            'dest_locn' => 'A1',
            'dest_conc' => '0.665',
            'volume' => '20.0'
          },
          'B1' => {
            'dest_locn' => 'B1',
            'dest_conc' => '0.343',
            'volume' => '20.0'
          },
          'C1' => {
            'dest_locn' => 'C1',
            'dest_conc' => '2.135',
            'volume' => '20.0'
          }
        }
      end
      let(:expected_attributes) do
        [
          {
            'uuid' => 'child_uuid',
            'well_location' => 'A1',
            'key' => 'concentration',
            'value' => '0.665',
            'units' => 'ng/ul',
            'cv' => 0,
            'assay_type' => subject.class.name.demodulize,
            'assay_version' => assay_version
          },
          {
            'uuid' => 'child_uuid',
            'well_location' => 'B1',
            'key' => 'concentration',
            'value' => '0.343',
            'units' => 'ng/ul',
            'cv' => 0,
            'assay_type' => subject.class.name.demodulize,
            'assay_version' => assay_version
          },
          {
            'uuid' => 'child_uuid',
            'well_location' => 'C1',
            'key' => 'concentration',
            'value' => '2.135',
            'units' => 'ng/ul',
            'cv' => 0,
            'assay_type' => subject.class.name.demodulize,
            'assay_version' => assay_version
          }
        ]
      end

      it 'creates the expected attibutes' do
        expect(subject.construct_dest_qc_assay_attributes('child_uuid', transfer_hash)).to eq(expected_attributes)
      end
    end
  end
end
