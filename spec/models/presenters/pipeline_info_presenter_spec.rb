# frozen_string_literal: true

RSpec.describe Presenters::PipelineInfoPresenter, type: :model do
  let(:presenter) { described_class.new(labware) }
  let(:labware) { double('Labware') }

  before do
    allow(labware).to receive(:purpose).and_return(double('Purpose', name: 'WGS Purpose'))
    allow(labware).to receive(:pooling_metadata).and_return({ 'key1' => { 'library_type' => { 'name' => 'WGS' } } })
    allow(labware).to receive(:ancestors).and_return([])
  end

  describe '#pipeline_groups' do
    context 'when pipelines match by purpose' do
      before do
        allow(Settings.pipelines).to receive(:list).and_return(
          [
            double('Pipeline', pipeline_group: 'Group A', relationships: { 'parent' => 'child' }, filters: {}),
            double('Pipeline', pipeline_group: 'Group B', relationships: { 'parent' => 'WGS Purpose' }, filters: {})
          ]
        )
      end

      it 'returns the pipeline groups matching the purpose' do
        expect(presenter.pipeline_groups).to eq(['Group B'])
      end
    end

    context 'when no pipelines match' do
      before do
        allow(Settings.pipelines).to receive(:list).and_return([])
        allow(Settings.pipelines).to receive(:select_pipelines_with_purpose).and_return([])
      end

      it 'returns nil' do
        expect(presenter.pipeline_groups).to be_nil
      end
    end

    context 'when pipelines match by library type' do
      before do
        pipelines = [
          double(
            'Pipeline',
            pipeline_group: 'Group A',
            relationships: {
              'parent' => 'WGS Purpose'
            },
            filters: {
              'library_type' => ['RNA-Seq']
            }
          ),
          double(
            'Pipeline',
            pipeline_group: 'Group B',
            relationships: {
              'parent' => 'WGS Purpose'
            },
            filters: {
              'library_type' => ['WGS']
            }
          )
        ]
        allow(Settings.pipelines).to receive(:list).and_return(pipelines)
        allow(Settings.pipelines).to receive(:select).and_return(pipelines)
      end

      it 'returns the pipeline groups matching the library type' do
        expect(presenter.pipeline_groups).to eq(['Group B'])
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

    context 'when no pipeline groups are present' do
      context 'as an empty array' do
        before { allow(presenter).to receive(:pipeline_groups).and_return(nil) }

        it 'returns a short message' do
          expect(presenter.pipeline_group_names).to eq('No Pipelines Found')
        end
      end

      context 'as nil' do
        it 'returns a short message' do
          expect(presenter.pipeline_group_names).to eq('No Pipelines Found')
        end
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
