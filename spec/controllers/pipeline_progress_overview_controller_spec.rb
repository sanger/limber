# frozen_string_literal: true

RSpec.describe PipelineProgressOverviewController, type: :controller do
  has_a_working_api

  let(:controller) { described_class.new }

  describe 'GET show' do
    let(:purposes) { create_list :v2_purpose, 2 }
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
      expect(controller.from_date({ date: date })).to eq date
    end

    it 'defaults to a month ago' do
      expect(controller.from_date({})).to eq Time.zone.today.prev_month
    end
  end
end
