# frozen_string_literal: true

RSpec.describe Presenters::PipelineInfoPresenter do
  let(:presenter) { described_class.new(labware) }
  let(:wgs_purpose) { create(:v2_purpose, uuid: 'wgs-purpose-uuid', name: 'WGS Purpose') }
  let(:labware) { create(:v2_stock_plate, :has_pooling_metadata, purpose: wgs_purpose) }

  before do
    allow(labware).to receive_messages(
      pooling_metadata: {
        'key1' => {
          'library_type' => {
            'name' => 'WGS'
          }
        }
      },
      ancestors: []
    )
  end

  describe '#pipeline_groups' do
    context 'when pipelines match by purpose' do
      let(:simplest_pipeline) do
        instance_double(Pipeline, pipeline_group: 'Group A', relationships: { 'parent' => 'child' }, filters: {})
      end
      let(:wgs_purpose_pipeline) do
        instance_double(Pipeline, pipeline_group: 'Group B', relationships: { 'parent' => 'WGS Purpose' }, filters: {})
      end

      before { allow(Settings.pipelines).to receive(:list).and_return([simplest_pipeline, wgs_purpose_pipeline]) }

      it 'returns the pipeline groups matching the purpose' do
        expect(presenter.pipeline_groups).to eq(['Group B'])
      end
    end

    context 'when no pipelines match' do
      before { allow(Settings.pipelines).to receive_messages(list: [], select_pipelines_with_purpose: []) }

      it 'returns nil' do
        expect(presenter.pipeline_groups).to be_nil
      end
    end

    context 'when pipelines match by library type' do
      let(:wgs_purpose_and_unrelated_library_type_pipeline) do
        instance_double(
          Pipeline,
          pipeline_group: 'Group C',
          relationships: {
            'parent' => 'WGS Purpose'
          },
          filters: {
            'library_type' => ['Unrelated']
          }
        )
      end
      let(:wgs_purpose_and_library_type_pipeline) do
        instance_double(
          Pipeline,
          pipeline_group: 'Group D',
          relationships: {
            'parent' => 'WGS Purpose'
          },
          filters: {
            'library_type' => ['WGS']
          }
        )
      end

      before do
        pipelines = [wgs_purpose_and_unrelated_library_type_pipeline, wgs_purpose_and_library_type_pipeline]
        allow(Settings.pipelines).to receive_messages(list: pipelines, select: pipelines)
      end

      it 'returns the pipeline groups matching the library type' do
        expect(presenter.pipeline_groups).to eq(['Group D'])
      end
    end
  end

  describe '#pipeline_group_names' do
    context 'when some pipeline groups are present' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(['Group A', 'Group B']) }

      it 'returns the pipeline group names' do
        expect(presenter.pipeline_group_names).to eq('Group A, Group B')
      end
    end

    context 'when many pipeline groups are present' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(['Group A', 'Group B', 'Group C', 'Group D']) }

      it 'returns the pipeline group names up to the limit' do
        expect(presenter.pipeline_group_names).to eq('Group A, Group B, Group C, ...(1 more)')
      end
    end

    context 'when no pipeline groups returns an empty array' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(nil) }

      it 'return a short message' do
        expect(presenter.pipeline_group_names).to eq('No Pipelines Found')
      end
    end

    context 'when pipeline groups returns nil' do
      it 'return a short message' do
        expect(presenter.pipeline_group_names).to eq('No Pipelines Found')
      end
    end
  end

  describe '#pipeline_group_name' do
    context 'when there is a single pipeline group' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(['Group A']) }

      it 'returns the pipeline group name' do
        expect(presenter.pipeline_group_name).to eq('Group A')
      end
    end

    context 'when there are no pipeline groups' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(nil) }

      it 'returns nil' do
        expect(presenter.pipeline_group_name).to be_nil
      end
    end

    context 'when there are multiple pipeline groups' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(['Group A', 'Group B']) }

      it 'returns nil' do
        expect(presenter.pipeline_group_name).to be_nil
      end
    end
  end
end
