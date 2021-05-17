# frozen_string_literal: true

RSpec.describe PipelineWorkInProgressController, type: :controller do
  has_a_working_api

  let(:controller){ described_class.new }

  describe 'GET index' do
    let(:labware) { create_list :labware, 2 }

    before do
      allow_any_instance_of(PipelineWorkInProgressController).to receive(:merge_page_results).and_return(labware)
    end

    it 'runs ok' do
      get :index, params: { date: Date.new(2020, 2, 5) } # why is this calling example.com?
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#from_date' do
    let(:date) { Date.new(2019, 5, 13) }

    it 'parses the date from the URL parameters' do
      expect(controller.from_date({ date: date })).to eq date
    end

    it 'defaults to a month ago' do
      expect(controller.from_date({})).to eq Date.today.prev_month
    end
  end

  describe '#combine_and_order_pipelines' do
    let(:filters) { {"request_type_key" => ["example_req_type"], "library_type" => ["example_lib_type"]} }

    context 'when the pipelines are simple' do
      let(:pipeline_1_config) do
        Pipeline.new(
          filters: filters,
          library_pass: "Purpose 3",
          relationships: {
            "Purpose 1" => "Purpose 2",
            "Purpose 2" => "Purpose 3"
          },
          name: "Pipeline A"
        )
      end

      let(:pipeline_2_config) do
        Pipeline.new(
          filters: filters,
          library_pass: "Purpose 4",
          relationships: {
            "Purpose 3" => "Purpose 4"
          },
          name: "Pipeline B"
        )
      end

      let(:pipeline_3_config) do
        Pipeline.new(
          filters: filters,
          library_pass: "Purpose 5",
          relationships: {
            "Purpose 4" => "Purpose 5"
          },
          name: "Pipeline B"
        )
      end

      let(:pipeline_configs) { [pipeline_1_config, pipeline_2_config, pipeline_3_config] }
      let(:expected_result) { ["Purpose 1", "Purpose 2", "Purpose 3", "Purpose 4", "Purpose 5"] }

      it 'returns the right list of purposes' do
        expect(controller.combine_and_order_pipelines(pipeline_configs)).to eq expected_result
      end
    end

    context 'when the relationship hashes are in the wrong order' do
      let(:pipeline_1_config) do
        Pipeline.new(
          filters: filters,
          library_pass: "Purpose 3",
          relationships: {
            "Purpose 2" => "Purpose 3",
            "Purpose 1" => "Purpose 2"
          },
          name: "Pipeline A"
        )
      end

      let(:pipeline_2_config) do
        Pipeline.new(
          filters: filters,
          library_pass: "Purpose 4",
          relationships: {
            "Purpose 3" => "Purpose 4"
          },
          name: "Pipeline B"
        )
      end

      let(:pipeline_configs) { [pipeline_1_config, pipeline_2_config] }
      let(:expected_result) { ["Purpose 1", "Purpose 2", "Purpose 3", "Purpose 4"] }

      it 'returns the right list of purposes' do
        expect(controller.combine_and_order_pipelines(pipeline_configs)).to eq expected_result
      end
    end

    context 'when there is only one pipeline' do
      let(:pipeline_1_config) do
        Pipeline.new(
          filters: filters,
          library_pass: "Purpose 3",
          relationships: {
            "Purpose 2" => "Purpose 3",
            "Purpose 1" => "Purpose 2"
          },
          name: "Pipeline A"
        )
      end

      let(:pipeline_configs) { [pipeline_1_config] }
      let(:expected_result) { ["Purpose 1", "Purpose 2", "Purpose 3"] }
    end

    context 'when there is branching' do
      let(:pipeline_1_config) do
        Pipeline.new(
          filters: filters,
          library_pass: "Purpose 3",
          relationships: {
            "Purpose 1" => "Purpose 2",
            "Purpose 2" => "Purpose 3"
          },
          name: "Pipeline A"
        )
      end

      let(:pipeline_2_config) do
        Pipeline.new(
          filters: filters,
          library_pass: "Purpose 4",
          relationships: {
            "Purpose 2" => "Purpose 4"
          },
          name: "Pipeline B"
        )
      end

      let(:pipeline_configs) { [pipeline_1_config, pipeline_2_config] }
      # Purposes 3 and 4 swap places if the arguments to above :pipeline_configs are passed in the other order
      let(:expected_result) { ["Purpose 1", "Purpose 2", "Purpose 3", "Purpose 4"] }

      it 'returns the right list of purposes' do
        expect(controller.combine_and_order_pipelines(pipeline_configs)).to eq expected_result
      end
    end

    context 'when there are two entry points' do
      let(:pipeline_1_config) do
        Pipeline.new(
          filters: filters,
          library_pass: "Purpose 3",
          relationships: {
            "Purpose 1" => "Purpose 2",
            "Purpose 3" => "Purpose 2",
            "Purpose 2" => "Purpose 4"
          },
          name: "Pipeline A"
        )
      end

      let(:pipeline_configs) { [pipeline_1_config] }
      let(:expected_result) { ["Purpose 1", "Purpose 3", "Purpose 2", "Purpose 4"] }

      it 'returns the right list of purposes' do
        expect(controller.combine_and_order_pipelines(pipeline_configs)).to eq expected_result
      end
    end

    context 'when the pipeline is a real one' do
      let(:pipeline_1_config) do
        Pipeline.new(
          filters: {"request_type_key" => ["limber_heron_lthr"], "library_type" => ["Sanger_tailed_artic_v1_384"]},
          library_pass: "LTHR-384 Lib PCR pool",
          relationships: {
            "LTHR Cherrypick" => "LTHR-384 RT-Q",
            "LTHR-384 RT-Q" => "LTHR-384 PCR 1",
            "LTHR-384 RT" => "LTHR-384 PCR 1",
            "LTHR-384 PCR 1" => "LTHR-384 Lib PCR 1",
            "LTHR-384 Lib PCR 1" => "LTHR-384 Lib PCR pool"
          },
          name: "Heron-384 Tailed A"
        )
      end

      let(:pipeline_2_config) do
        Pipeline.new(
          filters: {"request_type_key" => ["limber_heron_lthr"], "library_type" => ["Sanger_tailed_artic_v1_384"]},
          library_pass: "LTHR-384 Lib PCR pool",
          relationships: {
            "LTHR-384 RT-Q" => "LTHR-384 PCR 2",
            "LTHR-384 RT" => "LTHR-384 PCR 2",
            "LTHR-384 PCR 2" => "LTHR-384 Lib PCR 2",
            "LTHR-384 Lib PCR 2" => "LTHR-384 Lib PCR pool"
          },
          name: "Heron-384 Tailed B"
        )
      end

      let(:pipeline_configs) { [pipeline_1_config, pipeline_2_config] }
      let(:expected_result) { ["LTHR Cherrypick", "LTHR-384 RT", "LTHR-384 RT-Q", "LTHR-384 PCR 1", "LTHR-384 PCR 2", "LTHR-384 Lib PCR 1", "LTHR-384 Lib PCR 2", "LTHR-384 Lib PCR pool"] }

      it 'returns the right list of purposes' do
        expect(controller.combine_and_order_pipelines(pipeline_configs)).to eq expected_result
      end
    end

    context 'when the pipeline is circular' do
      let(:pipeline_1_config) do
        Pipeline.new(
          filters: filters,
          library_pass: "Purpose 3",
          relationships: {
            "Purpose 1" => "Purpose 2",
            "Purpose 2" => "Purpose 3",
            "Purpose 3" => "Purpose 1"
          },
          name: "Pipeline A"
        )
      end

      let(:pipeline_configs) { [pipeline_1_config] }
      let(:expected_result) { ["Purpose 1", "Purpose 2", "Purpose 3"] }

      it 'should error' do
        expect { controller.combine_and_order_pipelines(pipeline_configs) }.to raise_error("Pipeline config can't be flattened into a list of purposes")
      end
    end
  end

  describe '#retrieve_labware' do
    let(:page_size) { 2 }
    let(:purposes) { ['LTHR Cherrypick', 'LTHR-384 RT'] }
    let(:from_date) { Date.today.prev_month }
    let(:labware) { create_list :labware, 2 }

    before do
      allow(controller).to receive(:merge_page_results).and_return(labware)
    end

    it 'retrieves labware' do
      expect(controller.retrieve_labware(page_size, from_date, purposes)).to eq labware
    end
  end

  describe '#merge_page_results' do
    let(:query_builder){ Sequencescape::Api::V2::Labware.where(purpose_name: 'LTHR Cherrypick') }
    let(:query_builder_page_1){ Sequencescape::Api::V2::Labware.where(purpose_name: 'LTHR Cherrypick').page(1) }
    let(:query_builder_page_2){ Sequencescape::Api::V2::Labware.where(purpose_name: 'LTHR Cherrypick').page(2) }
    let(:page_size) { 2 }
    let(:labware_list_page_1) { create_list :labware, 2 }
    let(:labware_list_page_2) { create_list :labware, 1 }

    before do
      allow(query_builder).to receive(:page).with(1).and_return(query_builder_page_1)
      allow(query_builder_page_1).to receive(:to_a).and_return(labware_list_page_1)
      allow(query_builder).to receive(:page).with(2).and_return(query_builder_page_2)
      allow(query_builder_page_2).to receive(:to_a).and_return(labware_list_page_2)
    end

    it 'merges page results' do
      expect(controller.merge_page_results(query_builder, page_size)).to eq labware_list_page_1 + labware_list_page_2
    end
  end

  describe '#mould_data_for_view' do
    let(:purposes) { ['Limber Example Purpose', 'LTHR-384 RT'] }
    let(:labware_record_no_state) { create :labware_with_purpose }
    let(:labware_record_passsed) { create :labware_with_state_changes, target_state: 'passed' }
    let(:labware_record_cancelled) { create :labware_with_state_changes, target_state: 'cancelled' }
    let(:labware_records) { [labware_record_no_state, labware_record_passsed, labware_record_cancelled] }

    let(:expected_output) do
      {
        "Limber Example Purpose" => [
          {
            :record => labware_record_no_state,
            :state => "pending"
          },
          {
            :record => labware_record_passsed,
            :state => "passed"
          }
          # cancelled one not present
        ],
        "LTHR-384 RT" => []
      }
    end

    it 'returns the correct format' do
      expect(controller.mould_data_for_view(purposes, labware_records)).to eq expected_output
    end
  end
end
