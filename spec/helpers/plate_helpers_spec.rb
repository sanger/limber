# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PlateHelper do
  include described_class

  describe '#sorted_pre_cap_pool_json' do
    # create 3 pre-cap pools with ids not in sequential order
    let(:pre_cap_pool_1) { build :pre_capture_pool, id: 123, uuid: 'pre-cap-pool-1' }
    let(:pre_cap_pool_2) { build :pre_capture_pool, id: 122, uuid: 'pre-cap-pool-2' }
    let(:pre_cap_pool_3) { build :pre_capture_pool, id: 124, uuid: 'pre-cap-pool-3' }

    # Create requests for plate wells in 3 different pre-capture pools in mixed sequence
    # for A1
    let(:isc_library_request_1_1) do
      build :isc_library_request, pre_capture_pool: pre_cap_pool_1, submission_id: 1, order_id: 1
    end

    # for B1
    let(:isc_library_request_3_1) do
      build :isc_library_request, pre_capture_pool: pre_cap_pool_3, submission_id: 1, order_id: 3
    end

    # for C1
    let(:isc_library_request_1_2) do
      build :isc_library_request, pre_capture_pool: pre_cap_pool_1, submission_id: 1, order_id: 1
    end

    # for D1
    let(:isc_library_request_2_1) do
      build :isc_library_request, pre_capture_pool: pre_cap_pool_2, submission_id: 1, order_id: 2
    end

    # for E1
    let(:isc_library_request_1_3) do
      build :isc_library_request, pre_capture_pool: pre_cap_pool_1, submission_id: 1, order_id: 1
    end

    # for F1
    let(:isc_library_request_3_2) do
      build :isc_library_request, pre_capture_pool: pre_cap_pool_3, submission_id: 1, order_id: 3
    end

    # for G1
    let(:isc_library_request_2_2) do
      build :isc_library_request, pre_capture_pool: pre_cap_pool_2, submission_id: 1, order_id: 2
    end

    # for H1
    let(:isc_library_request_2_3) do
      build :isc_library_request, pre_capture_pool: pre_cap_pool_2, submission_id: 1, order_id: 2
    end

    # create the outer requests array to pass to the plate factory
    let(:outer_requests) do
      [
        isc_library_request_1_1,
        isc_library_request_3_1,
        isc_library_request_1_2,
        isc_library_request_2_1,
        isc_library_request_1_3,
        isc_library_request_3_2,
        isc_library_request_2_2,
        isc_library_request_2_3
      ]
    end

    let(:plate_for_precap) do
      build :v2_plate_for_pooling, state: 'passed', pool_sizes: [8], outer_requests: outer_requests
    end

    let(:expected_result) do
      [
        { 'pool_id' => 123, 'order_id' => '1', 'wells' => %w[A1 C1 E1] },
        { 'pool_id' => 122, 'order_id' => '2', 'wells' => %w[D1 G1 H1] },
        { 'pool_id' => 124, 'order_id' => '3', 'wells' => %w[B1 F1] }
      ]
    end

    it 'sorts the pre cap pools correctly' do
      pool_store_safebuffer = sorted_pre_cap_pool_json(plate_for_precap)
      pool_store = JSON.parse(pool_store_safebuffer.to_str.gsub('=>', ':'))

      expect(pool_store).to eq(expected_result)
    end
  end

  describe '#well_under_represented?' do
    context 'when the request has UNDER_REPRESENTED_KEY set to true' do
      let(:poly_metadatum) { build(:poly_metadatum, key: LimberConstants::UNDER_REPRESENTED_KEY, value: 'true') }
      let(:request) { build(:library_request_with_poly_metadata, poly_metadata: [poly_metadatum]) }
      let(:aliquot) { build(:v2_aliquot, outer_request: request) }
      let(:well) { build(:v2_well, location: 'A1', aliquots: [aliquot]) }

      it 'returns true' do
        expect(well_under_represented?(well)).to be true
      end
    end

    context 'when no request' do
      let(:aliquot) { build(:v2_aliquot, outer_request: nil) }
      let(:well) { build(:v2_well, location: 'A1', aliquots: [aliquot]) }

      it 'returns false' do
        expect(well_under_represented?(well)).to be false
      end
    end

    context 'when no poly_metadata present' do
      let(:request) { build(:library_request) }
      let(:aliquot) { build(:v2_aliquot, outer_request: request) }
      let(:well) { build(:v2_well, location: 'A1', aliquots: [aliquot]) }

      it 'returns false' do
        expect(well_under_represented?(well)).to be false
      end
    end

    context 'when metadata key is something else' do
      let(:request) do
        build(:library_request_with_poly_metadata,
              poly_metadata: [build(:poly_metadatum, key: 'other_key', value: 'true')])
      end
      let(:aliquot) { build(:v2_aliquot, outer_request: request) }
      let(:well) { build(:v2_well, location: 'A1', aliquots: [aliquot]) }

      it 'returns false' do
        expect(well_under_represented?(well)).to be false
      end
    end
  end
end
