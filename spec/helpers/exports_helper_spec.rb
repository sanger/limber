# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportsHelper do
  include ExportsHelper

  context 'each_source_metadata_for_plate' do
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
          position: { 'name' => 'A1' },
          transfer_requests_as_target: [transfer_request_from_a1, transfer_request_from_b1]
        )
      end
      let(:well_b1) do
        create(
          :v2_well_with_transfer_requests,
          position: { 'name' => 'B1' },
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
          position: { 'name' => 'B1' },
          transfer_requests_as_target: [transfer_request_from_c1]
        )
      end
      let(:plate) { create(:v2_plate, wells: [well_b1], pool_sizes: [1]) }

      it 'yields the correct value for transfers' do
        expect { |b| each_source_metadata_for_plate(plate, &b) }.to yield_with_args(
          ancestor_plate_barcode, 'C1', well_b1
        )
      end
    end

    context 'with no transfer request to destination wells' do
      let(:well_a1) { create(:v2_well_with_transfer_requests, position: { 'name' => 'A1' }, transfer_requests_as_target: []) }
      let(:well_b1) { create(:v2_well_with_transfer_requests, position: { 'name' => 'B1' }, transfer_requests_as_target: []) }
      let(:plate) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

      it 'yields nothing' do
        expect { |b| each_source_metadata_for_plate(plate, &b) }.not_to yield_control
      end
    end

    context 'with transfer requests with invalid source well names' do
      let(:ancestor_well_invalid_name_d1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'D1', name: 'D1') }
      let(:ancestor_well_invalid_name_e1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'E1', name: 'Barcode:E1:Extra') }

      let(:transfer_request_from_d1) { create(:v2_transfer_request, source_asset: ancestor_well_invalid_name_d1, target_asset: nil) }
      let(:transfer_request_from_e1) { create(:v2_transfer_request, source_asset: ancestor_well_invalid_name_e1, target_asset: nil) }

      let(:well_a1) do
        create(:v2_well_with_transfer_requests,
               position: { 'name' => 'A1' },
               transfer_requests_as_target: [transfer_request_from_d1])
      end
      let(:well_b1) do
        create(:v2_well_with_transfer_requests,
               position: { 'name' => 'B1' },
               transfer_requests_as_target: [transfer_request_from_e1])
      end
      let(:plate) { create(:v2_plate, wells: [well_a1, well_b1], pool_sizes: [1, 1]) }

      it 'yields nothing' do
        expect { |b| each_source_metadata_for_plate(plate, &b) }.not_to yield_control
      end
    end
  end
end
