# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::TubeRack, type: :model do
  describe '#requests_in_progress' do
    let!(:tube_rack) { create(:tube_rack, tubes: { A1: tube1, B1: tube2 }) }

    context 'when there are no requests' do
      let(:tube1) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: nil)]) }
      let(:tube2) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: nil)]) }

      it 'returns an empty array' do
        expect(tube_rack.requests_in_progress).to eq([])
      end
    end

    context 'when there are requests on the tube aliquots' do
      let(:request_type1) { create(:request_type, key: 'first_key') }
      let(:request_type2) { create(:request_type, key: 'second_key') }
      let(:request1) { create(:request, request_type: request_type1, state: 'started') }
      let(:request2) { create(:request, request_type: request_type2, state: 'started') }
      let(:tube1) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: request1)]) }
      let(:tube2) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: request2)]) }

      before do
        tube1
        tube2
      end

      it 'returns all requests in progress' do
        expect(tube_rack.requests_in_progress.map(&:id)).to contain_exactly(request1.id, request2.id)
      end

      it 'filters the first_key request to complete' do
        expect(tube_rack.requests_in_progress(request_types_to_complete: 'first_key').map(&:id)).to contain_exactly(
          request1.id
        )
      end

      it 'filters the second_key request to complete' do
        expect(tube_rack.requests_in_progress(request_types_to_complete: 'second_key').map(&:id)).to contain_exactly(
          request2.id
        )
      end
    end
  end

  describe '#all_requests' do
    let!(:tube_rack) { create(:tube_rack, tubes: { A1: tube1, B1: tube2 }) }

    context 'when there are no requests' do
      let(:tube1) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: nil)]) }
      let(:tube2) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: nil)]) }

      it 'returns an empty array' do
        expect(tube_rack.all_requests).to eq([])
      end
    end

    context 'when there are requests' do
      let(:request_type1) { create(:request_type, key: 'type1') }
      let(:request_type2) { create(:request_type, key: 'type2') }
      let(:request1) { create(:request, request_type: request_type1, state: 'started') }
      let(:request2) { create(:request, request_type: request_type2, state: 'started') }

      # set up tube 1 with a request as source
      let(:receptacle1) do
        create(
          :v2_receptacle,
          qc_results: [],
          aliquots: [create(:v2_aliquot, request: nil)],
          requests_as_source: [request1]
        )
      end
      let(:tube1) { create(:v2_tube, receptacle: receptacle1) }

      # set up tube 2 with an aliquot request
      let(:tube2) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: request2)]) }

      before do
        tube1
        tube2
      end

      it 'returns all requests associated with the tube rack' do
        expect(tube_rack.all_requests.map(&:id)).to contain_exactly(request1.id, request2.id)
      end
    end
  end

  describe '#to_param' do
    it 'returns the uuid of the TubeRack' do
      uuid = '123e4567-e89b-12d3-a456-426614174000'
      tube_rack = described_class.new(uuid:)

      expect(tube_rack.to_param).to eq(uuid)
    end
  end

  describe '#model_name' do
    let(:tube_rack) { described_class.new }
    let(:model_name) { tube_rack.model_name }

    it 'returns an instance of ActiveModel::Name' do
      expect(model_name).to be_an_instance_of(ActiveModel::Name)
    end

    it 'returns an instance with the correct parameters' do
      expect(model_name).to have_attributes(
        name: 'TubeRack',
        singular: 'tube_rack',
        plural: 'tube_racks',
        element: 'tube_rack',
        human: 'Tube rack',
        collection: 'tube_racks',
        param_key: 'tube_rack',
        i18n_key: :tube_rack,
        route_key: 'tube_racks',
        singular_route_key: 'tube_rack'
      )
    end
  end

  describe '#racked_tubes_in_columns' do
    let(:labware_uuid) { SecureRandom.uuid }

    let(:tube1_uuid) { SecureRandom.uuid }
    let(:tube2_uuid) { SecureRandom.uuid }
    let(:tube3_uuid) { SecureRandom.uuid }
    let(:tube4_uuid) { SecureRandom.uuid }
    let(:tube5_uuid) { SecureRandom.uuid }
    let(:tube6_uuid) { SecureRandom.uuid }

    let!(:tube1) { create :v2_tube, uuid: tube1_uuid, barcode_number: 1 }
    let!(:tube2) { create :v2_tube, uuid: tube2_uuid, barcode_number: 2 }
    let!(:tube3) { create :v2_tube, uuid: tube3_uuid, barcode_number: 3 }
    let!(:tube4) { create :v2_tube, uuid: tube4_uuid, barcode_number: 4 }
    let!(:tube5) { create :v2_tube, uuid: tube5_uuid, barcode_number: 5 }
    let!(:tube6) { create :v2_tube, uuid: tube6_uuid, barcode_number: 6 }

    let(:tubes) { { 'B1' => tube1, 'A1' => tube2, 'C1' => tube3, 'D3' => tube4, 'A3' => tube5, 'C2' => tube6 } }

    # NB. factory sets up the racked tubes given the tubes hash above
    let!(:tube_rack1) { create :tube_rack, barcode_number: 7, uuid: labware_uuid, tubes: tubes }

    it 'returns racked tubes sorted by coordinate' do
      sorted_racked_tubes = tube_rack1.racked_tubes_in_columns
      expect(sorted_racked_tubes.map(&:tube)).to eq([tube2, tube1, tube3, tube6, tube5, tube4])
    end

    it 'memoizes the sorted racked tubes' do
      expect(tube_rack1.racked_tubes_in_columns).to equal(tube_rack1.racked_tubes_in_columns)
    end

    context 'when there are single digit coordinates' do
      let(:tubes) { { 'C12' => tube1, 'A1' => tube2, 'C2' => tube3, 'D3' => tube4, 'A3' => tube5, 'C11' => tube6 } }

      it 'returns racked tubes sorted by coordinate' do
        sorted_racked_tubes = tube_rack1.racked_tubes_in_columns
        expect(sorted_racked_tubes.map(&:tube)).to eq([tube2, tube3, tube5, tube4, tube6, tube1])
      end
    end

    context 'when there are zero filled coordinates' do
      let(:tubes) { { 'C12' => tube1, 'A01' => tube2, 'C02' => tube3, 'D03' => tube4, 'A03' => tube5, 'C11' => tube6 } }

      it 'returns racked tubes sorted by coordinate' do
        sorted_racked_tubes = tube_rack1.racked_tubes_in_columns
        expect(sorted_racked_tubes.map(&:tube)).to eq([tube2, tube3, tube5, tube4, tube6, tube1])
      end
    end
  end

  describe '#state' do
    let(:tube1) { create :v2_tube, uuid: 'tube1_uuid', state: state_for_tube1, barcode_number: 1 }
    let(:tube2) { create :v2_tube, uuid: 'tube2_uuid', state: state_for_tube2, barcode_number: 2 }
    let(:tube3) { create :v2_tube, uuid: 'tube3_uuid', state: state_for_tube3, barcode_number: 3 }

    let(:tubes) { { 'A1' => tube1, 'B1' => tube2, 'C1' => tube3 } }

    let!(:test_tube_rack) { build :tube_rack, barcode_number: 5, tubes: tubes }

    context 'when all racked tubes have the same state' do
      let(:state_for_tube1) { 'pending' }
      let(:state_for_tube2) { 'pending' }
      let(:state_for_tube3) { 'pending' }

      it 'returns the state of the racked tubes' do
        expect(test_tube_rack.state).to eq('pending')
      end
    end

    context 'when the tube rack is empty' do
      let(:tubes) { {} }

      it 'returns "empty"' do
        expect(test_tube_rack.state).to eq('empty')
      end
    end

    context 'when racked tubes have mixed states' do
      let(:state_for_tube1) { 'pending' }
      let(:state_for_tube2) { 'passed' }
      let(:state_for_tube3) { 'pending' }

      it 'returns "mixed"' do
        expect(test_tube_rack.state).to eq('mixed')
      end
    end

    context 'when racked tubes have mixed states including cancelled and failed' do
      let(:state_for_tube1) { 'pending' }
      let(:state_for_tube2) { 'cancelled' }
      let(:state_for_tube3) { 'failed' }

      it 'returns the remaining state after filtering out cancelled and failed' do
        expect(test_tube_rack.state).to eq('pending')
      end
    end

    context 'when racked tubes have only cancelled and failed states' do
      let(:state_for_tube1) { 'failed' }
      let(:state_for_tube2) { 'cancelled' }
      let(:state_for_tube3) { 'failed' }

      it 'returns "failed" as we first filter the cancelled one out' do
        expect(test_tube_rack.state).to eq('failed')
      end
    end

    context 'when there are still mixed states after filtering out cancelled and failed' do
      let(:state_for_tube1) { 'pending' }
      let(:state_for_tube2) { 'passed' }
      let(:state_for_tube3) { 'failed' }
      let(:state_for_tube4) { 'cancelled' }

      let(:tube4) { create :v2_tube, uuid: 'tube3_uuid', state: state_for_tube4, barcode_number: 4 }

      let(:tubes) { { 'A1' => tube1, 'B1' => tube2, 'C1' => tube3, 'D1' => tube4 } }

      it 'returns "mixed"' do
        expect(test_tube_rack.state).to eq('mixed')
      end
    end
  end
end
