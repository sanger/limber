# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/plates_controller'

describe ExportsController, type: :controller do
  let(:plate_query) do
    pq = instance_double(JsonApiClient::Query::Builder)
    expect(pq).to receive(:first).and_return(plate)
    pq
  end

  let(:plate) { create :v2_plate, barcode_number: 1 }

  before do
    expect(Sequencescape::Api::V2::Plate).to receive(:where).with(barcode: 'DN1S').and_return(plate_query)
  end

  it 'renders a library_pooling csv' do
    get :show, params: { id: 'library_pool', limber_plate_id: 'DN1S' }, as: :csv
    expect(response).to have_http_status(:ok)
    expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
    expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
    expect(response).to render_template('library_pool')
    assert_equal 'text/csv', @response.content_type
  end

  it 'returns 404 with unknown templates' do
    expect do
      get :show, params: { id: 'not_a_template', limber_plate_id: 'DN1S' }, as: :csv
    end.to raise_error(ActionController::RoutingError, 'Unknown template not_a_template')
  end
end
