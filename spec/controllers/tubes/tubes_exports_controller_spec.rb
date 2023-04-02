# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/plates_controller'

RSpec.describe Tubes::TubesExportsController, type: :controller do
  let(:tube_includes) { 'transfer_requests_as_target.source_asset,aliquots,aliquots.sample.sample_metadata' }
  let(:tube) { create :v2_tube, barcode_number: 1 }
  let(:tube_barcode) { tube.barcode.human }

  RSpec.shared_examples 'a tsv view' do
    it 'renders the view' do
      get :show, params: { id: tsv_id, limber_tube_id: tube_barcode }, as: :tsv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Tube)
      expect(assigns(:tube)).to be_a(Sequencescape::Api::V2::Tube)
      expect(response).to render_template(expected_template)
      assert_equal content_type, @response.content_type
      expect(@response.get_header('Content-Disposition')).to include(tube_barcode)
    end
  end

  context 'on generating a csv' do
    before do
      expect(Sequencescape::Api::V2).to receive(:tube_with_custom_includes)
        .with(includes, barcode: tube_barcode)
        .and_return(tube)
    end

    context 'where tsv id requested is bioscan_mbrave.tsv' do
      let(:includes) { tube_includes }
      let(:tsv_id) { 'bioscan_mbrave' }
      let(:expected_template) { 'bioscan_mbrave' }
      let(:content_type) { 'text/tab-separated-values; charset=utf-8' }

      it_behaves_like 'a tsv view'
    end
  end

  context 'where default' do
    let(:includes) { 'wells' }

    it 'returns 404 with unknown templates' do
      expect { get :show, params: { id: 'not_a_template', limber_tube_id: tube_barcode }, as: :csv }.to raise_error(
        ActionController::RoutingError,
        'Unknown template not_a_template'
      )
    end
  end
end
