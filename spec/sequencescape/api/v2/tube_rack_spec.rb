# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::TubeRack, type: :model do
  let!(:tube_rack) { create(:tube_rack, tubes: { A1: tube1, B1: tube2 }) }

  describe '#requests_in_progress' do
    context 'when there are no requests' do
      let(:tube1) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: nil)]) }
      let(:tube2) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: nil)]) }

      it 'returns an empty array' do
        expect(tube_rack.requests_in_progress).to eq([])
      end
    end

    context 'when there are requests on the tube aliquots' do
      let(:request_type1) { create(:request_type, key: 'type1') }
      let(:request_type2) { create(:request_type, key: 'type2') }
      let(:request1) { create(:request, request_type: request_type1, state: 'started') }
      let(:request2) { create(:request, request_type: request_type2, state: 'started') }
      let(:tube1) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: request1)]) }
      let(:tube2) { create(:v2_tube, aliquots: [create(:v2_aliquot, request: request2)]) }

      before do
        tube1
        tube2
      end

      it 'returns all requests in progress' do
        expect(tube_rack.requests_in_progress.map(&:id)).to match_array([request1.id, request2.id])
      end

      it 'filters requests by request types to complete' do
        expect(tube_rack.requests_in_progress(request_types_to_complete: 'type1').map(&:id)).to match_array(
          [request1.id]
        )
        expect(tube_rack.requests_in_progress(request_types_to_complete: 'type2').map(&:id)).to match_array(
          [request2.id]
        )
      end
    end
  end

  describe '#all_requests' do
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
        expect(tube_rack.all_requests.map(&:id)).to match_array([request1.id, request2.id])
      end
    end
  end
end
