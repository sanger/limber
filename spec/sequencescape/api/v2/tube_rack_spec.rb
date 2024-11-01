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
        expect(tube_rack.all_requests.map(&:id)).to match_array([request1.id, request2.id])
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
    it 'returns an instance of ActiveModel::Name with the correct parameters' do
      tube_rack = described_class.new
      model_name = tube_rack.model_name

      expect(model_name).to be_an_instance_of(ActiveModel::Name)
      expect(model_name.name).to eq('Limber::TubeRack')
      expect(model_name.singular).to eq('limber_tube_rack')
      expect(model_name.plural).to eq('limber_tube_racks')
      expect(model_name.element).to eq('tube_rack')
      expect(model_name.human).to eq('Tube rack')
      expect(model_name.collection).to eq('limber/tube_racks')
      expect(model_name.param_key).to eq('limber_tube_rack')
      expect(model_name.i18n_key).to eq(:'limber/tube_rack')
      expect(model_name.route_key).to eq('limber_tube_racks')
      expect(model_name.singular_route_key).to eq('limber_tube_rack')
    end
  end
end
