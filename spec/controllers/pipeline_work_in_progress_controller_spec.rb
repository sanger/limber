# frozen_string_literal: true

RSpec.describe PipelineWorkInProgressController, type: :controller do
  let(:controller) { described_class.new }

  describe 'GET show' do
    let(:purposes) { create_list :purpose, 2 }
    let(:purpose_names) { purposes.map(&:name) }
    let(:labware) { create_list :labware, 2, purpose: purposes[0] }

    before do
      allow(Settings.pipelines).to receive(:combine_and_order_pipelines).and_return(purpose_names)
      allow(Sequencescape::Api::V2).to receive(:merge_page_results).and_return(labware)
    end

    it 'runs ok' do
      get :show, params: { id: 'Heron-384 V2', date: Date.new(2020, 2, 5) }
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#from_date' do
    let(:date) { Date.new(2019, 5, 13) }

    it 'parses the date from the URL parameters' do
      expect(controller.from_date({ date: })).to eq date
    end

    it 'defaults to a month ago' do
      expect(controller.from_date({})).to eq Time.zone.today.prev_month
    end
  end

  describe '#retrieve_labware' do
    let(:page_size) { 2 }
    let(:purposes) { ['LTHR Cherrypick', 'LTHR-384 RT'] }
    let(:from_date) { Time.zone.today.prev_month }
    let(:labware) { create_list :labware, 2 }

    before { allow(Sequencescape::Api::V2).to receive(:merge_page_results).and_return(labware) }

    it 'retrieves labware' do
      expect(controller.retrieve_labware(page_size, from_date, purposes)).to eq labware
    end
  end

  describe '#mould_data_for_view' do
    let(:purposes) { create_list :purpose, 2 }
    let(:purpose_names) { purposes.map(&:name) }
    let(:labware_record_no_state) { create :labware, purpose: purposes[0] }
    let(:labware_record_passed) { create :labware_with_state_changes, purpose: purposes[0], target_state: 'passed' }
    let(:labware_record_cancelled) do
      create :labware_with_state_changes, purpose: purposes[0], target_state: 'cancelled'
    end
    let(:labware_records) { [labware_record_no_state, labware_record_passed, labware_record_cancelled] }

    it 'returns the correct format' do
      expected_output = {
        purposes[0].name => [
          { record: labware_record_no_state, state: 'pending' },
          { record: labware_record_passed, state: 'passed' }
          # cancelled one not present
        ],
        purposes[1].name => []
      }

      expect(controller.mould_data_for_view(purpose_names, labware_records)).to eq expected_output
    end
  end

  describe '#arrange_labware_records' do
    let(:pipeline_purposes) { create_list :purpose, 3 }
    let(:another_purpose) { create :purpose }

    let(:pipeline_purpose_names) { pipeline_purposes.map(&:name) }

    let(:pipeline_ancestor1) { create :labware, purpose: pipeline_purposes[0] }
    let(:pipeline_ancestor2) { create :labware, purpose: pipeline_purposes[1] }
    let(:another_ancestor) { create :labware, purpose: another_purpose }

    let(:valid_labware1) { create :labware, purpose: pipeline_purposes[0] }
    let(:valid_labware2) { create :labware, purpose: pipeline_purposes[1] }
    let(:valid_labware3) { create :labware, purpose: pipeline_purposes[1], ancestors: [pipeline_ancestor1] }
    let(:valid_labware4) { create :labware, purpose: pipeline_purposes[2], ancestors: [pipeline_ancestor1] }
    let(:valid_labware5) { create :labware, purpose: pipeline_purposes[2], ancestors: [pipeline_ancestor2] }
    let(:valid_labware6) do
      create :labware, purpose: pipeline_purposes[2], ancestors: [pipeline_ancestor1, pipeline_ancestor2]
    end
    let(:valid_labware7) do
      create :labware,
             purpose: pipeline_purposes[2],
             ancestors: [pipeline_ancestor1, pipeline_ancestor2, another_ancestor]
    end
    let(:valid_labware) do
      [valid_labware1, valid_labware2, valid_labware3, valid_labware4, valid_labware5, valid_labware6, valid_labware7]
    end

    let(:invalid_labware1) { create :labware, purpose: pipeline_purposes[2] }
    let(:invalid_labware2) { create :labware, purpose: pipeline_purposes[2], ancestors: [another_ancestor] }
    let(:invalid_labware) { [invalid_labware1, invalid_labware2] }

    let(:all_labware) { valid_labware + invalid_labware }
    let(:specific_labware) { all_labware.select { |lw| pipeline_purposes.take(2).include? lw.purpose } }
    let(:general_labware) { all_labware.select { |lw| lw.purpose == pipeline_purposes.last } }

    before do
      allow(Sequencescape::Api::V2).to receive(:merge_page_results).and_return(specific_labware, general_labware)
    end

    it 'filters the final purpose for labware with ancestors from previous purposes' do
      actual = controller.arrange_labware_records(pipeline_purpose_names, '2020-08-25')
      expected = valid_labware

      expect(actual).to eq expected
    end
  end
end
