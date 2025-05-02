# frozen_string_literal: true

RSpec.describe Pipeline do
  let(:model) { described_class.new(pipeline_config) }

  describe '#active_for?' do
    context 'when there are filters and the labware is a plate' do
      let(:filters) { { 'request_type_key' => ['limber_wgs'], 'library_type' => ['Standard'] } }

      let(:pipeline_config) do
        {
          pipeline_group: 'Group A',
          filters: filters,
          library_pass: 'Purpose 3',
          relationships: {
            'Purpose 1' => 'Purpose 2',
            'Purpose 2' => 'Purpose 3'
          },
          name: 'Pipeline A'
        }
      end

      context 'when there is a pipeline group' do
        let(:labware) { create :v2_stock_plate, pool_sizes: [1] }

        it 'sets the pipeline_group attribute provided' do
          expect(model.pipeline_group).to eq 'Group A'
        end
      end

      context 'when there is no pipeline group' do
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
        let(:labware) { create :v2_stock_plate, pool_sizes: [1] }

        it 'sets the pipeline_group to the pipeline name' do
          expect(model.pipeline_group).to eq 'Pipeline A'
        end
      end

      context 'when the labware requests match the filters' do
        # Specifying pool_sizes means the factory produces a plate where the wells have requests coming out of them.
        let(:labware) { create :v2_stock_plate, pool_sizes: [1] }

        it 'returns true' do
          expect(model.active_for?(labware)).to be true
        end
      end

      context 'when the labware requests do not match the filters' do
        let(:labware) { create :v2_stock_plate }

        it 'returns false' do
          expect(model.active_for?(labware)).to be false
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
        expect(model.active_for?(labware)).to be true
      end
    end
  end
end
