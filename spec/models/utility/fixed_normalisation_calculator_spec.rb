# frozen_string_literal: true

RSpec.describe Utility::FixedNormalisationCalculator do
  context 'when computing values for fixed normalisation' do
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
        'source_volume' => 2,
        'diluent_volume' => 33
      }
    end

    subject do
      Utility::FixedNormalisationCalculator.new(dilutions_config)
    end

    describe '#source_multiplication_factor' do
      it 'calculates value correctly' do
        expect(subject.source_multiplication_factor).to eq(BigDecimal('2.0'))
      end
    end

    describe '#dest_multiplication_factor' do
      it 'calculates value correctly' do
        expect(subject.dest_multiplication_factor).to eq(BigDecimal('35.0'))
      end
    end

    describe '#compute_well_amounts' do
      it 'calculates plate well amounts correctly' do
        expected_amounts = {
          'A1' => BigDecimal('3.0'),
          'B1' => BigDecimal('112.0'),
          'C1' => BigDecimal('7.0'),
          'D1' => BigDecimal('3.6')
        }

        expect(subject.compute_well_amounts(parent_plate)).to eq(expected_amounts)
      end
    end

    describe '#compute_well_transfers' do
      let(:expd_transfers) do
        {
          'A1' => { 'dest_locn' => 'A1', 'dest_conc' => '0.086' },
          'B1' => { 'dest_locn' => 'B1', 'dest_conc' => '3.2' },
          'C1' => { 'dest_locn' => 'C1', 'dest_conc' => '0.2' },
          'D1' => { 'dest_locn' => 'D1', 'dest_conc' => '0.103' }
        }
      end

      it 'creates the correct transfers' do
        expect(subject.compute_well_transfers(parent_plate)).to eq(expd_transfers)
      end
    end

    describe '#extract_destination_concentrations' do
      context 'when extracting the destination concentrations' do
        let(:transfer_hash) do
          {
            'A1' => { 'dest_locn' => 'A2', 'dest_conc' => BigDecimal('0.665') },
            'B1' => { 'dest_locn' => 'A1', 'dest_conc' => BigDecimal('0.343') },
            'C1' => { 'dest_locn' => 'A3', 'dest_conc' => BigDecimal('2.135') },
            'D1' => { 'dest_locn' => 'B3', 'dest_conc' => BigDecimal('3.123') },
            'E1' => { 'dest_locn' => 'C3', 'dest_conc' => BigDecimal('3.045') },
            'F1' => { 'dest_locn' => 'B2', 'dest_conc' => BigDecimal('0.743') },
            'G1' => { 'dest_locn' => 'C2', 'dest_conc' => BigDecimal('0.693') }
          }
        end
        let(:expected_dest_concs) do
          {
            'A2' => BigDecimal('0.665'),
            'A1' => BigDecimal('0.343'),
            'A3' => BigDecimal('2.135'),
            'B3' => BigDecimal('3.123'),
            'C3' => BigDecimal('3.045'),
            'B2' => BigDecimal('0.743'),
            'C2' => BigDecimal('0.693')
          }
        end

        it 'refactors the transfers hash correctly' do
          expect(subject.extract_destination_concentrations(transfer_hash)).to eq(expected_dest_concs)
        end
      end
    end

    describe '#construct_dest_qc_assay_attributes' do
      let(:transfer_hash) do
        {
          'A1' => { 'dest_locn' => 'A2', 'dest_conc' => BigDecimal('0.665'), 'volume' => BigDecimal('20.0') },
          'B1' => { 'dest_locn' => 'A1', 'dest_conc' => BigDecimal('0.343'), 'volume' => BigDecimal('20.0') },
          'C1' => { 'dest_locn' => 'A3', 'dest_conc' => BigDecimal('2.135'), 'volume' => BigDecimal('20.0') }
        }
      end
      let(:expected_attributes) do
        [
          {
            'uuid' => 'child_uuid',
            'well_location' => 'A2',
            'key' => 'concentration',
            'value' => BigDecimal('0.665'),
            'units' => 'ng/ul',
            'cv' => 0,
            'assay_type' => 'FixedNormalisationCalculator',
            'assay_version' => assay_version
          },
          {
            'uuid' => 'child_uuid',
            'well_location' => 'A1',
            'key' => 'concentration',
            'value' => BigDecimal('0.343'),
            'units' => 'ng/ul',
            'cv' => 0,
            'assay_type' => 'FixedNormalisationCalculator',
            'assay_version' => assay_version
          },
          {
            'uuid' => 'child_uuid',
            'well_location' => 'A3',
            'key' => 'concentration',
            'value' => BigDecimal('2.135'),
            'units' => 'ng/ul',
            'cv' => 0,
            'assay_type' => 'FixedNormalisationCalculator',
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
