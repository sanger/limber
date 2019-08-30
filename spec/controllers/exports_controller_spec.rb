# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/plates_controller'

RSpec.describe ExportsController, type: :controller do
  let(:plate) { create :v2_plate, barcode_number: 1 }
  let(:plate_barcode) { 'DN1S' }

  before do
    expect(Sequencescape::Api::V2).to receive(:plate_with_custom_includes).with(includes, barcode: plate_barcode).and_return(plate)
  end

  context 'where template concentrations_ngul' do
    let(:includes) { 'wells.qc_results' }

    it 'renders a concentrations_ngul.csv' do
      get :show, params: { id: 'concentrations_ngul', limber_plate_id: plate_barcode }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('concentrations_ngul')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template concentrations_nM' do
    let(:includes) { 'wells.qc_results' }

    it 'renders a concentrations_nm.csv' do
      get :show, params: { id: 'concentrations_nm', limber_plate_id: plate_barcode }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('concentrations_nm')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton aggregate cherrypick' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_aggregate_cherrypick.csv' do
      get :show, params: { id: 'hamilton_aggregate_cherrypick', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_aggregate_cherrypick')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton cherrypick to sample dilution' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_cherrypick_to_sample_dilution.csv' do
      get :show, params: { id: 'hamilton_cherrypick_to_sample_dilution', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_cherrypick_to_sample_dilution')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton gex dil to gex frag 2xp' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_gex_dil_to_gex_frag_2xp.csv' do
      get :show, params: { id: 'hamilton_gex_dil_to_gex_frag_2xp', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_gex_dil_to_gex_frag_2xp')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton gex frag 2xp to gex ligxp' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_gex_frag_2xp_to_gex_ligxp.csv' do
      get :show, params: { id: 'hamilton_gex_frag_2xp_to_gex_ligxp', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_gex_frag_2xp_to_gex_ligxp')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton cherrypick to 5p gex dilution' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_cherrypick_to_5p_gex_dilution.csv' do
      get :show, params: { id: 'hamilton_cherrypick_to_5p_gex_dilution', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_cherrypick_to_5p_gex_dilution')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton cherrypick to bcr dilution1' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_cherrypick_to_bcr_dilution1.csv' do
      get :show, params: { id: 'hamilton_cherrypick_to_bcr_dilution1', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_cherrypick_to_bcr_dilution1')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton lbc bcr dil 1 to lbc bcr enrich1 1xspri' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_lbc_bcr_dil_1_to_lbc_bcr_enrich1_1xspri.csv' do
      get :show, params: { id: 'hamilton_lbc_bcr_dil_1_to_lbc_bcr_enrich1_1xspri', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_lbc_bcr_dil_1_to_lbc_bcr_enrich1_1xspri')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton lbc bcr dil 2 to lbc bcr post lig 1xspri' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_lbc_bcr_dil_2_to_lbc_bcr_post_lig_1xspri.csv' do
      get :show, params: { id: 'hamilton_lbc_bcr_dil_2_to_lbc_bcr_post_lig_1xspri', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_lbc_bcr_dil_2_to_lbc_bcr_post_lig_1xspri')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton lbc bcr enrich1 1xspri to lbc bcr enrich2 2xspri' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_lbc_bcr_enrich1_1xspri_to_lbc_bcr_enrich2_2xspri.csv' do
      get :show, params: { id: 'hamilton_lbc_bcr_enrich1_1xspri_to_lbc_bcr_enrich2_2xspri', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_lbc_bcr_enrich1_1xspri_to_lbc_bcr_enrich2_2xspri')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton lbc bcr enrich2 2xspri to lbc bcr dil 2' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_lbc_bcr_enrich2_2xspri_to_lbc_bcr_dil_2.csv' do
      get :show, params: { id: 'hamilton_lbc_bcr_enrich2_2xspri_to_lbc_bcr_dil_2', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_lbc_bcr_enrich2_2xspri_to_lbc_bcr_dil_2')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton cherrypick to tcr dilution1' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_cherrypick_to_tcr_dilution1.csv' do
      get :show, params: { id: 'hamilton_cherrypick_to_tcr_dilution1', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_cherrypick_to_tcr_dilution1')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton lbc tcr dil 1 to lbc tcr enrich1 1xspri' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_lbc_tcr_dil_1_to_lbc_tcr_enrich1_1xspri.csv' do
      get :show, params: { id: 'hamilton_lbc_tcr_dil_1_to_lbc_tcr_enrich1_1xspri', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_lbc_tcr_dil_1_to_lbc_tcr_enrich1_1xspri')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton lbc tcr dil 2 to lbc tcr post lig 1xspri' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_lbc_tcr_dil_2_to_lbc_tcr_post_lig_1xspri.csv' do
      get :show, params: { id: 'hamilton_lbc_tcr_dil_2_to_lbc_tcr_post_lig_1xspri', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_lbc_tcr_dil_2_to_lbc_tcr_post_lig_1xspri')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton lbc tcr enrich1 1xspri to lbc tcr enrich2 2xspri' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_lbc_tcr_enrich1_1xspri_to_lbc_tcr_enrich2_2xspri.csv' do
      get :show, params: { id: 'hamilton_lbc_tcr_enrich1_1xspri_to_lbc_tcr_enrich2_2xspri', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_lbc_tcr_enrich1_1xspri_to_lbc_tcr_enrich2_2xspri')
      assert_equal 'text/csv', @response.content_type
    end
  end

  context 'where template hamilton lbc tcr enrich2 2xspri to lbc tcr dil 2' do
    let(:includes) { 'wells.transfer_requests_as_target.source_asset' }

    it 'renders a hamilton_lbc_tcr_enrich2_2xspri_to_lbc_tcr_dil_2.csv' do
      get :show, params: { id: 'hamilton_lbc_tcr_enrich2_2xspri_to_lbc_tcr_dil_2', limber_plate_id: 'DN1S' }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template('hamilton_lbc_tcr_enrich2_2xspri_to_lbc_tcr_dil_2')
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
