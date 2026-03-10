# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::BioscanSubmissionPlatePresenter do
  describe '#active_pipelines' do
    let(:purpose_name) { 'Bioscan Purpose' }
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
    let(:presenter) { described_class.new(labware:) }

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
        'bioscan_pipeline' => {
          pipeline_group: 'Group A',
          relationships: {
            'parent' => 'Bioscan Purpose'
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
        expect(presenter.active_pipelines).to include(have_attributes(name: 'bioscan_pipeline'))
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
end
