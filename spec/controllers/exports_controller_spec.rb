# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/plates_controller'

RSpec.describe ExportsController, type: :controller do
  let(:plate) { create :v2_plate, barcode_number: 1 }
  let(:plate_barcode) { 'DN1S' }

  before do
    expect(Sequencescape::Api::V2).to receive(:plate_with_custom_includes).with(includes, plate_barcode).and_return(plate)
  end

  context 'where template concentrations' do
    let(:includes) { 'wells.qc_results' }

    it 'renders a concentrations.csv' do
      get :show, params: { id: 'concentrations', limber_plate_id: plate_barcode }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('concentrations')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton aggregate cherry pick' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_aggregate_cherry_pick.csv' do
      get :show, params: { id: 'hamilton_aggregate_cherry_pick', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_aggregate_cherry_pick')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where default' do
    let(:includes) { 'wells' }

    it 'returns 404 with unknown templates' do
      expect do
        get :show, params: { id: 'not_a_template', limber_plate_id: 'DN1S' }, as: :csv
      end.to raise_error(ActionController::RoutingError, 'Unknown template not_a_template')
    end
  end
end
