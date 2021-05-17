# frozen_string_literal: true

RSpec.describe PipelineWorkInProgressController, type: :controller do
  let(:controller){ described_class.new }

  describe '#index' do
    it 'runs ok'
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
    it 'returns the correct format'
    it 'errors if the input unexpected'
  end
end
