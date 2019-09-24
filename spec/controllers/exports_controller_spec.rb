# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/plates_controller'

RSpec.describe ExportsController, type: :controller do
  let(:well_qc_includes) { 'wells.qc_results' }
  let(:well_src_asset_includes) { 'wells.transfer_requests_as_target.source_asset' }
  let(:plate) { create :v2_plate, barcode_number: 1 }
  let(:plate_barcode) { 'DN1S' }

  RSpec.shared_examples 'a csv view' do
    it 'renders the view' do
      get :show, params: { id: csv_id, limber_plate_id: plate_barcode }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template(expected_template)
      assert_equal 'text/csv', @response.content_type
    end
  end

  RSpec.shared_examples 'a hamilton fixed volume dilutions view' do
    let(:expected_template) { 'hamilton_fixed_volume_dilutions' }

    it_behaves_like 'a csv view'
  end

  RSpec.shared_examples 'a hamilton variable volume dilutions view' do
    let(:expected_template) { 'hamilton_variable_volume_dilutions' }

    it_behaves_like 'a csv view'
  end

  RSpec.shared_examples 'a hamilton plate stamp view' do
    let(:expected_template) { 'hamilton_plate_stamp' }

    it_behaves_like 'a csv view'
  end

  context 'on generating a csv' do
    before do
      expect(Sequencescape::Api::V2).to receive(:plate_with_custom_includes).with(includes, barcode: plate_barcode).and_return(plate)
    end

    context 'where csv id requested is concentrations_ngul.csv' do
      let(:includes) { well_qc_includes }
      let(:csv_id) { 'concentrations_ngul' }
      let(:expected_template) { 'concentrations_ngul' }

      it_behaves_like 'a csv view'
    end

    context 'where csv id requested is concentrations_nM.csv' do
      let(:includes) { well_qc_includes }
      let(:csv_id) { 'concentrations_nm' }
      let(:expected_template) { 'concentrations_nm' }

      it_behaves_like 'a csv view'
    end

    context 'where template is for the hamilton robot' do
      let(:includes) { well_src_asset_includes }

      context 'where csv id requested is hamilton_aggregate_cherrypick.csv' do
        let(:csv_id) { 'hamilton_aggregate_cherrypick' }
        let(:expected_template) { 'hamilton_aggregate_cherrypick' }

        it_behaves_like 'a csv view'
      end

      context 'where csv id requested is hamilton_cherrypick_to_sample_dilution.csv' do
        let(:csv_id) { 'hamilton_cherrypick_to_sample_dilution' }

        it_behaves_like 'a hamilton fixed volume dilutions view'
      end

      context 'where csv id requested is hamilton_gex_dil_to_gex_frag_2xp.csv' do
        let(:csv_id) { 'hamilton_gex_dil_to_gex_frag_2xp' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_gex_frag_2xp_to_gex_ligxp.csv' do
        let(:csv_id) { 'hamilton_gex_frag_2xp_to_gex_ligxp' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_cherrypick_to_5p_gex_dilution.csv' do
        let(:csv_id) { 'hamilton_cherrypick_to_5p_gex_dilution' }

        it_behaves_like 'a hamilton variable volume dilutions view'
      end

      context 'where csv id requested is hamilton_cherrypick_to_bcr_dilution1.csv' do
        let(:csv_id) { 'hamilton_cherrypick_to_bcr_dilution1' }

        it_behaves_like 'a hamilton fixed volume dilutions view'
      end

      context 'where csv id requested is hamilton_lbc_bcr_dil_1_to_lbc_bcr_enrich1_1xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_bcr_dil_1_to_lbc_bcr_enrich1_1xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_bcr_dil_2_to_lbc_bcr_post_lig_1xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_bcr_dil_2_to_lbc_bcr_post_lig_1xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_bcr_enrich1_1xspri_to_lbc_bcr_enrich2_2xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_bcr_enrich1_1xspri_to_lbc_bcr_enrich2_2xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_bcr_enrich2_2xspri_to_lbc_bcr_dil_2.csv' do
        let(:csv_id) { 'hamilton_lbc_bcr_enrich2_2xspri_to_lbc_bcr_dil_2' }

        it_behaves_like 'a hamilton variable volume dilutions view'
      end

      context 'where csv id requested is hamilton_cherrypick_to_tcr_dilution1.csv' do
        let(:csv_id) { 'hamilton_cherrypick_to_tcr_dilution1' }

        it_behaves_like 'a hamilton fixed volume dilutions view'
      end

      context 'where csv id requested is hamilton_lbc_tcr_dil_1_to_lbc_tcr_enrich1_1xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_tcr_dil_1_to_lbc_tcr_enrich1_1xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_tcr_dil_2_to_lbc_tcr_post_lig_1xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_tcr_dil_2_to_lbc_tcr_post_lig_1xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_tcr_enrich1_1xspri_to_lbc_tcr_enrich2_2xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_tcr_enrich1_1xspri_to_lbc_tcr_enrich2_2xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_tcr_enrich2_2xspri_to_lbc_tcr_dil_2.csv' do
        let(:csv_id) { 'hamilton_lbc_tcr_enrich2_2xspri_to_lbc_tcr_dil_2' }

        it_behaves_like 'a hamilton variable volume dilutions view'
      end
    end
  end

  context 'where default' do
    let(:includes) { 'wells' }

    it 'returns 404 with unknown templates' do
      expect do
        get :show, params: { id: 'not_a_template', limber_plate_id: plate_barcode }, as: :csv
      end.to raise_error(ActionController::RoutingError, 'Unknown template not_a_template')
    end
  end
end
