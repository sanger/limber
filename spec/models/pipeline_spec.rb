# frozen_string_literal: true

RSpec.describe Pipeline do
  let(:model) { described_class.new(pipeline_config) }

  describe '#active_for?' do
    let(:filters) { { 'request_type_key' => ['example_req_type'], 'library_type' => ['example_lib_type'] } }

    context 'when there are filters and the labware is a plate' do
      let(:pipeline_config) do
        {
          filters: filters,
          library_pass: 'Purpose 3',
          relationships: {
            'Purpose 1' => 'Purpose 2',
            'Purpose 2' => 'Purpose 3'
          },
          name: 'Pipeline A'
        }
      end

      # TODO: fix
      # context 'when the labware requests match the filters' do
      #   let(:labware) { create :v2_stock_plate }
      #   let(:well) { create :v2_stock_well }

      #   it 'returns true' do
      #     puts "labware wells: #{labware.wells}"
      #     puts "labware wells class: #{labware.wells.first.class}"
      #     puts "labware requests: #{labware.active_requests}"
      #     binding.pry
      #     # TODO: the plate made by the factory doesn't have requests, despite using v2_stock_well (which does have requests)
      #     expect(model.active_for?(labware)).to eq true
      #   end
      # end

      context 'when the labware requests do not match the filters' do
        let(:labware) { create :v2_stock_plate }

        it 'returns false' do
          expect(model.active_for?(labware)).to eq false
        end
      end
    end

    context 'when there are no filters and the labware is a tube' do
      let(:pipeline_config) do
        {
          library_pass: 'Purpose 3',
          relationships: {
            'Purpose 1' => 'Purpose 2',
            'Purpose 2' => 'Purpose 3'
          },
          name: 'Pipeline A'
        }
      end

      let(:labware) { create :v2_tube }

      it 'returns true always' do
        expect(model.active_for?(labware)).to eq true
      end
    end
  end
end
