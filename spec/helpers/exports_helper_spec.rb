# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportsHelper do
  include described_class

  describe '#each_source_metadata_for_plate' do
    let(:ancestor_plate_barcode) { 'ANCESTOR_PLATE' }
    let(:ancestor_well_a1) { create(:well, plate_barcode: ancestor_plate_barcode, location: 'A1') }
    let(:ancestor_well_b1) { create(:well, plate_barcode: ancestor_plate_barcode, location: 'B1') }
    let(:ancestor_well_c1) { create(:well, plate_barcode: ancestor_plate_barcode, location: 'C1') }

    let(:transfer_request_from_a1) { create(:transfer_request, source_asset: ancestor_well_a1, target_asset: nil) }
    let(:transfer_request_from_b1) { create(:transfer_request, source_asset: ancestor_well_b1, target_asset: nil) }
    let(:transfer_request_from_c1) { create(:transfer_request, source_asset: ancestor_well_c1, target_asset: nil) }

    context 'with two transfer requests to A1 and one to B1' do
      let(:well_a1) do
        create(
          :well_with_transfer_requests,
          position: {
            'name' => 'A1'
          },
          transfer_requests_as_target: [transfer_request_from_a1, transfer_request_from_b1]
        )
      end
      let(:well_b1) do
        create(
          :well_with_transfer_requests,
          position: {
            'name' => 'B1'
          },
          transfer_requests_as_target: [transfer_request_from_c1]
        )
      end
      let(:plate) { create(:plate, wells: [well_a1, well_b1], pool_sizes: [2, 1]) }

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
          :well_with_transfer_requests,
          position: {
            'name' => 'B1'
          },
          transfer_requests_as_target: [transfer_request_from_c1]
        )
      end
      let(:plate) { create(:plate, wells: [well_b1], pool_sizes: [1]) }

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
        create(:well_with_transfer_requests, position: { 'name' => 'A1' }, transfer_requests_as_target: [])
      end
      let(:well_b1) do
        create(:well_with_transfer_requests, position: { 'name' => 'B1' }, transfer_requests_as_target: [])
      end
      let(:plate) { create(:plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

      it 'yields nothing' do
        expect { |b| each_source_metadata_for_plate(plate, &b) }.not_to yield_control
      end
    end

    context 'with transfer requests with invalid source well names' do
      let(:ancestor_well_invalid_name_d1) do
        create(:well, plate_barcode: ancestor_plate_barcode, location: 'D1', name: 'D1')
      end
      let(:ancestor_well_invalid_name_e1) do
        create(:well, plate_barcode: ancestor_plate_barcode, location: 'E1', name: 'Barcode:E1:Extra')
      end

      let(:transfer_request_from_d1) do
        create(:transfer_request, source_asset: ancestor_well_invalid_name_d1, target_asset: nil)
      end
      let(:transfer_request_from_e1) do
        create(:transfer_request, source_asset: ancestor_well_invalid_name_e1, target_asset: nil)
      end

      let(:well_a1) do
        create(
          :well_with_transfer_requests,
          position: {
            'name' => 'A1'
          },
          transfer_requests_as_target: [transfer_request_from_d1]
        )
      end
      let(:well_b1) do
        create(
          :well_with_transfer_requests,
          position: {
            'name' => 'B1'
          },
          transfer_requests_as_target: [transfer_request_from_e1]
        )
      end
      let(:plate) { create(:plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

      it 'yields nothing' do
        expect { |b| each_source_metadata_for_plate(plate, &b) }.not_to yield_control
      end
    end
  end

  describe '#aliquots_count_for' do
    subject { aliquots_count_for(well) }

    context 'when a basic single sample well' do
      let(:well) { create :well }

      it { is_expected.to eq 1 }
    end

    context 'when a basic multi sample well' do
      let(:well) { create :well, aliquot_count: 3 }

      it { is_expected.to eq 3 }
    end

    context 'a well with a multiple samples' do
      let(:aliquot1) { create :aliquot }
      let(:aliquot2) { create :aliquot }
      let(:well) { create(:well, aliquots: [aliquot1, aliquot2]) }
      let(:aliquot_count) { 2 }

      it { is_expected.to eq aliquot_count }
    end
  end
end
