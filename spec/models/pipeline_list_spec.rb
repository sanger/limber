# frozen_string_literal: true

RSpec.describe PipelineList do
  let(:model) { described_class.new(pipeline_config) }

  describe '#combine_and_order_pipelines' do
    let(:filters) { { 'request_type' => ['example_req_type'], 'library_type' => ['example_lib_type'] } }

    context 'when the pipelines are simple' do
      let(:pipeline_config) do
        {
          'Pipeline A' => {
            filters: filters,
            library_pass: 'Purpose 3',
            relationships: {
              'Purpose 1' => 'Purpose 2',
              'Purpose 2' => 'Purpose 3'
            },
            name: 'Pipeline A'
          },
          'Pipeline B' => {
            filters: filters,
            library_pass: 'Purpose 4',
            relationships: {
              'Purpose 3' => 'Purpose 4'
            },
            name: 'Pipeline B'
          },
          'Pipeline C' => {
            filters: filters,
            library_pass: 'Purpose 5',
            relationships: {
              'Purpose 4' => 'Purpose 5'
            },
            name: 'Pipeline C'
          }
        }
      end

      let(:pipeline_names) { ['Pipeline A', 'Pipeline B', 'Pipeline C'] }
      let(:expected_result) { ['Purpose 1', 'Purpose 2', 'Purpose 3', 'Purpose 4', 'Purpose 5'] }

      it 'returns the right list of purposes' do
        expect(model.combine_and_order_pipelines(pipeline_names)).to eq expected_result
      end
    end

    context 'when the relationship hashes are in the wrong order' do
      let(:pipeline_config) do
        {
          'Pipeline A' => {
            filters: filters,
            library_pass: 'Purpose 3',
            relationships: {
              'Purpose 2' => 'Purpose 3',
              'Purpose 1' => 'Purpose 2'
            },
            name: 'Pipeline A'
          },
          'Pipeline B' => {
            filters: filters,
            library_pass: 'Purpose 4',
            relationships: {
              'Purpose 3' => 'Purpose 4'
            },
            name: 'Pipeline B'
          }
        }
      end

      let(:pipeline_names) { ['Pipeline A', 'Pipeline B'] }
      let(:expected_result) { ['Purpose 1', 'Purpose 2', 'Purpose 3', 'Purpose 4'] }

      it 'returns the right list of purposes' do
        expect(model.combine_and_order_pipelines(pipeline_names)).to eq expected_result
      end
    end

    context 'when there is only one pipeline' do
      let(:pipeline_config) do
        {
          'Pipeline A' => {
            filters: filters,
            library_pass: 'Purpose 3',
            relationships: {
              'Purpose 2' => 'Purpose 3',
              'Purpose 1' => 'Purpose 2'
            },
            name: 'Pipeline A'
          }
        }
      end

      let(:pipeline_names) { ['Pipeline A'] }
      let(:expected_result) { ['Purpose 1', 'Purpose 2', 'Purpose 3'] }

      it 'returns the right list of purposes' do
        expect(model.combine_and_order_pipelines(pipeline_names)).to eq expected_result
      end
    end

    context 'when there is branching' do
      let(:pipeline_config) do
        {
          'Pipeline A' => {
            filters: filters,
            library_pass: 'Purpose 3',
            relationships: {
              'Purpose 1' => 'Purpose 2',
              'Purpose 2' => 'Purpose 3'
            },
            name: 'Pipeline A'
          },
          'Pipeline B' => {
            filters: filters,
            library_pass: 'Purpose 4',
            relationships: {
              'Purpose 2' => 'Purpose 4'
            },
            name: 'Pipeline B'
          }
        }
      end

      let(:pipeline_names) { ['Pipeline A', 'Pipeline B'] }

      # Purposes 3 and 4 swap places if the arguments to above :pipeline_names are passed in the other order
      let(:expected_result) { ['Purpose 1', 'Purpose 2', 'Purpose 3', 'Purpose 4'] }

      it 'returns the right list of purposes' do
        expect(model.combine_and_order_pipelines(pipeline_names)).to eq expected_result
      end
    end

    context 'when there is a pipeline_group' do
      let(:pipeline_config) do
        {
          'Pipeline A' => {
            pipeline_group: 'Pipeline X',
            filters: filters,
            library_pass: 'Purpose 3',
            relationships: {
              'Purpose 1' => 'Purpose 2',
              'Purpose 2' => 'Purpose 3'
            },
            name: 'Pipeline A'
          },
          'Pipeline B' => {
            pipeline_group: 'Pipeline X',
            filters: filters,
            library_pass: 'Purpose 4',
            relationships: {
              'Purpose 2' => 'Purpose 4'
            },
            name: 'Pipeline B'
          }
        }
      end

      let(:expected_result) { ['Pipeline A', 'Pipeline B'] }

      it 'returns a hash with the group and relevant pipelines' do
        expect(model.retrieve_pipeline_config_for_group('Pipeline X')).to eq expected_result
      end
    end

    context 'when there are two entry points' do
      let(:pipeline_config) do
        {
          'Pipeline A' => {
            filters: filters,
            library_pass: 'Purpose 3',
            relationships: {
              'Purpose 1' => 'Purpose 2',
              'Purpose 3' => 'Purpose 2',
              'Purpose 2' => 'Purpose 4'
            },
            name: 'Pipeline A'
          }
        }
      end

      let(:pipeline_names) { ['Pipeline A'] }
      let(:expected_result) { ['Purpose 1', 'Purpose 3', 'Purpose 2', 'Purpose 4'] }

      it 'returns the right list of purposes' do
        expect(model.combine_and_order_pipelines(pipeline_names)).to eq expected_result
      end
    end

    context 'when the pipeline is a real one' do
      let(:pipeline_config) do
        {
          'Heron-384 Tailed A' => {
            filters: {
              'request_type' => ['limber_heron_lthr'],
              'library_type' => ['Sanger_tailed_artic_v1_384']
            },
            library_pass: 'LTHR-384 Lib PCR pool',
            relationships: {
              'LTHR Cherrypick' => 'LTHR-384 RT-Q',
              'LTHR-384 RT-Q' => 'LTHR-384 PCR 1',
              'LTHR-384 RT' => 'LTHR-384 PCR 1',
              'LTHR-384 PCR 1' => 'LTHR-384 Lib PCR 1',
              'LTHR-384 Lib PCR 1' => 'LTHR-384 Lib PCR pool'
            },
            name: 'Heron-384 Tailed A'
          },
          'Heron-384 Tailed B' => {
            filters: {
              'request_type' => ['limber_heron_lthr'],
              'library_type' => ['Sanger_tailed_artic_v1_384']
            },
            library_pass: 'LTHR-384 Lib PCR pool',
            relationships: {
              'LTHR-384 RT-Q' => 'LTHR-384 PCR 2',
              'LTHR-384 RT' => 'LTHR-384 PCR 2',
              'LTHR-384 PCR 2' => 'LTHR-384 Lib PCR 2',
              'LTHR-384 Lib PCR 2' => 'LTHR-384 Lib PCR pool'
            },
            name: 'Heron-384 Tailed B'
          }
        }
      end

      let(:pipeline_names) { ['Heron-384 Tailed A', 'Heron-384 Tailed B'] }
      let(:expected_result) do
        [
          'LTHR Cherrypick',
          'LTHR-384 RT',
          'LTHR-384 RT-Q',
          'LTHR-384 PCR 1',
          'LTHR-384 PCR 2',
          'LTHR-384 Lib PCR 1',
          'LTHR-384 Lib PCR 2',
          'LTHR-384 Lib PCR pool'
        ]
      end

      it 'returns the right list of purposes' do
        expect(model.combine_and_order_pipelines(pipeline_names)).to eq expected_result
      end
    end

    context 'when the pipeline is circular' do
      let(:pipeline_config) do
        {
          'Pipeline A' => {
            filters: filters,
            library_pass: 'Purpose 3',
            relationships: {
              'Purpose 1' => 'Purpose 2',
              'Purpose 2' => 'Purpose 3',
              'Purpose 3' => 'Purpose 1'
            },
            name: 'Pipeline A'
          }
        }
      end

      let(:pipeline_names) { ['Pipeline A'] }

      it 'errors' do
        expect { model.combine_and_order_pipelines(pipeline_names) }.to raise_error(
          "Pipeline config can't be flattened into a list of purposes"
        )
      end
    end
  end
end
