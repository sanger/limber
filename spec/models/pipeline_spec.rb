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
      # Specifying pool_sizes means the factory produces a plate where the wells have requests coming out of them.
      let(:labware) { create :v2_stock_plate, purpose_name: 'Purpose 2', pool_sizes: [1] }

      context 'when there is a pipeline group' do
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

        it 'sets the pipeline_group to the pipeline name' do
          expect(model.pipeline_group).to eq 'Pipeline A'
        end
      end

      context 'when the labware requests match the filters' do
        it 'returns true' do
          expect(model.active_for?(labware)).to be true
        end
      end

      context 'when the labware requests do not match the filters' do
        # Produce a plate with no requests from the wells
        let(:labware) { create :v2_stock_plate, purpose_name: 'Purpose 2', pool_sizes: [0] }

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

      let(:labware) { create :v2_tube, purpose_name: 'Purpose 2' }

      it 'returns true always' do
        expect(model.active_for?(labware)).to be true
      end
    end
  end

  describe '#purpose_in_relationships?' do
    let(:purpose) { create(:v2_purpose, name: purpose_name) }

    context 'when the purpose is in the relationships key' do
      let(:pipeline_config) do
        { relationships: { 'Purpose 1' => 'Purpose 2', 'Purpose 2' => 'Purpose 3' }, name: 'Pipeline A' }
      end
      let(:purpose_name) { 'Purpose 1' }

      it 'returns true' do
        expect(model.purpose_in_relationships?(purpose)).to be true
      end
    end

    context 'when the purpose is in the relationships values' do
      let(:pipeline_config) do
        { relationships: { 'Purpose 1' => 'Purpose 2', 'Purpose 2' => 'Purpose 3' }, name: 'Pipeline A' }
      end
      let(:purpose_name) { 'Purpose 3' }

      it 'returns true' do
        expect(model.purpose_in_relationships?(purpose)).to be true
      end
    end

    context 'when the purpose is not in the relationships' do
      let(:pipeline_config) do
        { relationships: { 'Purpose 1' => 'Purpose 2', 'Purpose 2' => 'Purpose 3' }, name: 'Pipeline A' }
      end
      let(:purpose_name) { 'Purpose 4' }

      it 'returns false' do
        expect(model.purpose_in_relationships?(purpose)).to be false
      end
    end
  end
end
