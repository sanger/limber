# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportsHelper do
  include ExportsHelper

  describe '#each_source_metadata_for_plate' do
    let(:ancestor_plate_barcode) { 'ANCESTOR_PLATE' }
    let(:ancestor_well_a1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'A1') }
    let(:ancestor_well_b1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'B1') }
    let(:ancestor_well_c1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'C1') }

    let(:transfer_request_from_a1) { create(:v2_transfer_request, source_asset: ancestor_well_a1, target_asset: nil) }
    let(:transfer_request_from_b1) { create(:v2_transfer_request, source_asset: ancestor_well_b1, target_asset: nil) }
    let(:transfer_request_from_c1) { create(:v2_transfer_request, source_asset: ancestor_well_c1, target_asset: nil) }

    context 'with two transfer requests to A1 and one to B1' do
      let(:well_a1) do
        create(
          :v2_well_with_transfer_requests,
          position: {
            'name' => 'A1'
          },
          transfer_requests_as_target: [transfer_request_from_a1, transfer_request_from_b1]
        )
      end
      let(:well_b1) do
        create(
          :v2_well_with_transfer_requests,
          position: {
            'name' => 'B1'
          },
          transfer_requests_as_target: [transfer_request_from_c1]
        )
      end
      let(:plate) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [2, 1]) }

      it 'yields the correct values for transfers' do
        expect { |b| each_source_metadata_for_plate(plate, &b) }.to yield_successive_args(
          [ancestor_plate_barcode, 'A1', well_a1],
          [ancestor_plate_barcode, 'B1', well_a1],
          [ancestor_plate_barcode, 'C1', well_b1]
        )
      end
    end

    context 'with one transfer request to B1 only' do
      let(:well_b1) do
        create(
          :v2_well_with_transfer_requests,
          position: {
            'name' => 'B1'
          },
          transfer_requests_as_target: [transfer_request_from_c1]
        )
      end
      let(:plate) { create(:v2_plate, wells: [well_b1], pool_sizes: [1]) }

      it 'yields the correct value for transfers' do
        expect { |b| each_source_metadata_for_plate(plate, &b) }.to yield_with_args(
          ancestor_plate_barcode,
          'C1',
          well_b1
        )
      end
    end

    context 'with no transfer request to destination wells' do
      let(:well_a1) do
        create(:v2_well_with_transfer_requests, position: { 'name' => 'A1' }, transfer_requests_as_target: [])
      end
      let(:well_b1) do
        create(:v2_well_with_transfer_requests, position: { 'name' => 'B1' }, transfer_requests_as_target: [])
      end
      let(:plate) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

      it 'yields nothing' do
        expect { |b| each_source_metadata_for_plate(plate, &b) }.not_to yield_control
      end
    end

    context 'with transfer requests with invalid source well names' do
      let(:ancestor_well_invalid_name_d1) do
        create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'D1', name: 'D1')
      end
      let(:ancestor_well_invalid_name_e1) do
        create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'E1', name: 'Barcode:E1:Extra')
      end

      let(:transfer_request_from_d1) do
        create(:v2_transfer_request, source_asset: ancestor_well_invalid_name_d1, target_asset: nil)
      end
      let(:transfer_request_from_e1) do
        create(:v2_transfer_request, source_asset: ancestor_well_invalid_name_e1, target_asset: nil)
      end

      let(:well_a1) do
        create(
          :v2_well_with_transfer_requests,
          position: {
            'name' => 'A1'
          },
          transfer_requests_as_target: [transfer_request_from_d1]
        )
      end
      let(:well_b1) do
        create(
          :v2_well_with_transfer_requests,
          position: {
            'name' => 'B1'
          },
          transfer_requests_as_target: [transfer_request_from_e1]
        )
      end
      let(:plate) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

      it 'yields nothing' do
        expect { |b| each_source_metadata_for_plate(plate, &b) }.not_to yield_control
      end
    end
  end

  describe '#aliquots_count_for' do
    subject { aliquots_count_for(well) }

    context 'when a basic single sample well' do
      let(:well) { create :v2_well }
      it { is_expected.to eq 1 }
    end

    context 'when a basic multi sample well' do
      let(:well) { create :v2_well, aliquot_count: 3 }
      it { is_expected.to eq 3 }
    end

    context 'a well with a multiple samples' do
      let(:aliquot1) { create :v2_aliquot }
      let(:aliquot2) { create :v2_aliquot }
      let(:well) { create(:v2_well, aliquots: [aliquot1, aliquot2]) }
      let(:aliquot_count) { 2 }
      it { is_expected.to eq aliquot_count }
    end
  end

  describe '#mbrave_supplier_name_parts' do
    it 'extracts parts' do
      supplier_name = 'sample_SQPU_38225_F_D3'
      parts = mbrave_supplier_name_parts(supplier_name)
      expect(parts[0]).to eq(38_225)
      expect(parts[1]).to eq('F')
      expect(parts[2]).to eq('D')
      expect(parts[3]).to eq(3)
    end

    it 'can handle empty plate suffix' do
      supplier_name = 'sample_SQPU-38225-D12'
      parts = mbrave_supplier_name_parts(supplier_name)
      expect(parts[0]).to eq(38_225)
      expect(parts[1]).to eq('')
      expect(parts[2]).to eq('D')
      expect(parts[3]).to eq(12)
    end
  end

  describe '#mbrave_row_comparison' do
    it 'compares 384 plates' do
      row_a = ['x', 'x', 'CONTROL_POS_DescriptionSQPU-38224-E_A1', 'x', 1, 'x']
      row_b = ['x', 'x', 'sample_SQPU-38228-I_A1', 'x', 2, 'x']
      expect(mbrave_row_comparison(row_a, row_b)).to eq(-1)
    end

    it 'compares 96 plate number' do
      row_a = ['x', 'x', 'sample_SQPU-38225-F_A1', 'x', 1, 'x']
      row_b = ['x', 'x', 'sample_SQPU-38226-G_A1', 'x', 1, 'x']
      expect(mbrave_row_comparison(row_a, row_b)).to eq(-1)
    end

    it 'compares 96 plate suffix' do
      row_a = ['x', 'x', 'sample_SQPU-38225-F_A1', 'x', 1, 'x']
      row_b = ['x', 'x', 'sample_SQPU-38225-G_A1', 'x', 1, 'x']
      expect(mbrave_row_comparison(row_a, row_b)).to eq(-1)
    end

    it 'compares well rows' do
      row_a = ['x', 'x', 'sample_SQPU-38225-F_A1', 'x', 1, 'x']
      row_b = ['x', 'x', 'sample_SQPU-38225-F_B1', 'x', 1, 'x']
      expect(mbrave_row_comparison(row_a, row_b)).to eq(-1)
    end

    it 'compares well columns' do
      row_a = ['x', 'x', 'sample_SQPU-38225-F_A1', 'x', 1, 'x']
      row_b = ['x', 'x', 'sample_SQPU-38225-F_A2', 'x', 1, 'x']
      expect(mbrave_row_comparison(row_a, row_b)).to eq(-1)
    end

    it 'compares invalid' do
      row_a = ['x', 'x', 'x', 'x', 1, 'x']
      row_b = ['x', 'x', 'x', 'x', 1, 'x']
      expect(mbrave_row_comparison(row_a, row_b)).to eq(0)
    end
  end
end
