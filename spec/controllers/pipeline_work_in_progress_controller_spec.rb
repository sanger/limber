# frozen_string_literal: true

RSpec.describe PipelineWorkInProgressController, type: :controller do
  has_a_working_api

  let(:controller) { described_class.new }

  describe 'GET show' do
    let(:labware) { create_list :labware, 2 }

    before do
      allow(Sequencescape::Api::V2).to receive(:merge_page_results).and_return(labware)
    end

    it 'runs ok' do
      get :show, params: { id: 'heron', date: Date.new(2020, 2, 5) }
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#from_date' do
    let(:date) { Date.new(2019, 5, 13) }

    it 'parses the date from the URL parameters' do
      expect(controller.from_date({ date: date })).to eq date
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

    before do
      allow(Sequencescape::Api::V2).to receive(:merge_page_results).and_return(labware)
    end

    it 'retrieves labware' do
      expect(controller.retrieve_labware(page_size, from_date, purposes)).to eq labware
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
        'Limber Example Purpose' => [
          {
            record: labware_record_no_state,
            state: 'pending'
          },
          {
            record: labware_record_passsed,
            state: 'passed'
          }
          # cancelled one not present
        ],
        'LTHR-384 RT' => []
      }
    end

    it 'returns the correct format' do
      expect(controller.mould_data_for_view(purposes, labware_records)).to eq expected_output
    end
  end
end
