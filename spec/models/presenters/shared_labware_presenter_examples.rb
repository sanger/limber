# frozen_string_literal: true

RSpec.shared_examples 'a labware presenter' do
  it 'returns labware' do
    expect(subject.labware).to eq(labware)
  end

  it 'provides a document title' do
    expect(subject.document_title).to eq("#{purpose_name} (#{labware.human_barcode})")
  end

  it 'provides a content title' do
    expect(subject.content_title).to eq(title)
  end

  it 'has a state' do
    expect(subject.state).to eq(state)
  end

  it 'has a summary' do
    expect { |b| subject.summary(&b) }.to yield_successive_args(*summary_tab)
  end

  it 'has a sidebar partial' do
    expect(subject.sidebar_partial).to eq(sidebar_partial)
  end

  it 'responds to child_assets' do
    expect(subject).to respond_to(:child_assets)
  end

  it 'initializes with an empty array' do
    expect(subject.info_messages).to eq([])
  end
end

RSpec.shared_examples 'a stock presenter' do
  it 'prevents state change' do
    expect { |b| subject.default_state_change(&b) }.not_to yield_control
  end

  it 'displays its own barcode as stock' do
    expect(subject.input_barcode).to eq(barcode_string)
  end
end

RSpec.shared_examples 'a presenter defining active pipelines as having active requests' do |presenter_factory|
  let(:purpose_name) { 'Test Purpose' }
  let(:study) { create :study, name: 'Submission Study' }
  let(:project) { create :project, name: 'Submission Project' }

  let(:labware) do
    create :plate,
           well_count: 2,
           purpose_name: purpose_name,
           barcode_number: 2,
           aliquots_without_requests: 2,
           study: study,
           project: project
  end
  let(:presenter) { presenter_factory.call(labware) }

  let(:library_type_name) { 'LibTypeA' }
  let(:request_type_a) { create :request_type, key: 'rt_a' }
  let(:request_in_progress) do
    create :library_request,
           request_type: request_type_a,
           uuid: 'request-0',
           library_type: library_type_name,
           state: 'pending'
  end

  let(:request_completed) do
    create :library_request,
           request_type: request_type_a,
           uuid: 'request-1',
           library_type: library_type_name,
           state: 'passed'
  end

  let(:filters) { { request_type_key: ['rt_a'] } }
  let(:pipelines_config) do
    {
      'test_pipeline' => {
        pipeline_group: 'Group A',
        relationships: {
          'parent' => 'Test Purpose'
        },
        filters: filters
      }
    }
  end

  before do
    Settings.pipelines = PipelineList.new(pipelines_config)
    allow(labware.wells.first).to receive(:requests_as_source).and_return(requests_as_source_list)
  end

  context 'when there is an active request' do
    let(:requests_as_source_list) { [request_in_progress] }

    it 'returns a pipeline when there is an active request' do
      expect(presenter.active_pipelines).to include(have_attributes(name: 'test_pipeline'))
    end
  end

  context 'when no requests as source' do
    let(:requests_as_source_list) { [] }

    it 'does not return a pipeline when there are no active requests' do
      expect(presenter.active_pipelines).to be_empty
    end
  end

  context 'when only completed requests' do
    let(:requests_as_source_list) { [request_completed] }

    it 'does not return a pipeline when the only requests are completed' do
      expect(presenter.active_pipelines).to be_empty
    end
  end
end
