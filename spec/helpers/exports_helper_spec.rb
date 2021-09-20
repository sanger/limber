# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportsHelper do
  include ExportsHelper

  context 'each_source_metadata_for_plate' do
    let(:ancestor_plate_barcode) { 'ANCESTOR_PLATE' }
    let(:concentration_result) { create(:qc_result_concentration) }
    let(:ancestor_well_a1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'A1') }
    let(:ancestor_well_b1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'B1') }
    let(:ancestor_well_c1) { create(:v2_well, plate_barcode: ancestor_plate_barcode, location: 'C1') }

    let(:transfer_request_from_a1) { create(:v2_transfer_request, source_asset: ancestor_well_a1, target_asset: nil) }
    let(:transfer_request_from_b1) { create(:v2_transfer_request, source_asset: ancestor_well_b1, target_asset: nil) }
    let(:transfer_request_from_c1) { create(:v2_transfer_request, source_asset: ancestor_well_c1, target_asset: nil) }

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

    context 'with two transfer requests to A1 and one to B1' do
      it 'yields the correct values for transfers' do
        expect { |b| each_source_metadata_for_plate(plate, &b) }.to yield_successive_args(
          [ancestor_plate_barcode, 'A1', well_a1],
          [ancestor_plate_barcode, 'B1', well_a1],
          [ancestor_plate_barcode, 'C1', well_b1]
        )
      end
    end
  end
end
