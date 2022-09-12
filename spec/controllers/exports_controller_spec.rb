# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/plates_controller'

RSpec.describe ExportsController, type: :controller do
  let(:default_plate_includes) { 'wells' }
  let(:well_qc_includes) { 'wells.qc_results' }
  let(:well_qc_and_aliquot_request_includes) { 'wells.qc_results,wells.aliquots.request' }
  let(:well_src_asset_includes) { 'wells.transfer_requests_as_target.source_asset' }
  let(:well_qc_and_requests_as_target_includes) { 'wells.qc_results,wells.requests_as_target' }
  let(:plate) { create :v2_plate, barcode_number: 1 }
  let(:plate_barcode) { 'DN1S' }

  RSpec.shared_examples 'a csv view' do
    it 'renders the view' do
      get :show, params: { id: csv_id, limber_plate_id: plate_barcode }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template(expected_template)
      assert_equal 'text/csv; charset=utf-8', @response.content_type
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

  RSpec.shared_examples 'a hamilton variable volume dilutions with well diluents view' do
    let(:expected_template) { 'hamilton_variable_volume_dilutions_with_well_diluents' }

    it_behaves_like 'a csv view'
  end

  RSpec.shared_examples 'a hamilton cherrypick dilutions view' do
    let(:expected_template) { 'hamilton_cherrypick_dilutions' }

    it_behaves_like 'a csv view'
  end

  context 'on generating a csv' do
    before do
      expect(Sequencescape::Api::V2).to receive(:plate_with_custom_includes)
        .with(includes, barcode: plate_barcode)
        .and_return(plate)
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

    # Duplex Seq
    context 'where csv id requested is duplex_seq_al_lib_concentrations_for_customer.csv' do
      let(:includes) { well_qc_and_aliquot_request_includes }
      let(:csv_id) { 'duplex_seq_al_lib_concentrations_for_customer' }
      let(:expected_template) { 'duplex_seq_al_lib_concentrations_for_customer' }

      it_behaves_like 'a csv view'
    end

    context 'where csv id requested is duplex_seq_pcr_xp_merged_summary_file_for_rearray.csv' do
      let(:includes) { well_qc_and_requests_as_target_includes }
      let(:csv_id) { 'duplex_seq_pcr_xp_merged_summary_file_for_rearray' }
      let(:expected_template) { 'duplex_seq_pcr_xp_merged_summary_file_for_rearray' }

      it_behaves_like 'a csv view'
    end

    # end Duplex Seq

    # Targeted Nanoseq
    context 'where csv id requested is targeted_nanoseq_al_lib_concentrations_for_customer.csv' do
      let(:includes) { well_qc_and_aliquot_request_includes }
      let(:csv_id) { 'targeted_nanoseq_al_lib_concentrations_for_customer' }
      let(:expected_template) { 'targeted_nanoseq_al_lib_concentrations_for_customer' }

      it_behaves_like 'a csv view'
    end

    context 'where csv id requested is targeted_nanoseq_pcr_xp_merged_summary_file_for_rearray.csv' do
      let(:includes) { well_qc_and_requests_as_target_includes }
      let(:csv_id) { 'targeted_nanoseq_pcr_xp_merged_summary_file_for_rearray' }
      let(:expected_template) { 'targeted_nanoseq_pcr_xp_merged_summary_file_for_rearray' }

      it_behaves_like 'a csv view'
    end

    # end Targeted Nanoseq

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

        it_behaves_like 'a hamilton cherrypick dilutions view'
      end

      context 'where csv id requested is hamilton_lbc_bcr_dil_1_to_lbc_bcr_enrich1_2xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_bcr_dil_1_to_lbc_bcr_enrich1_2xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_bcr_dil_2_to_lbc_bcr_post_lig_1xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_bcr_dil_2_to_lbc_bcr_post_lig_1xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_bcr_enrich1_2xspri_to_lbc_bcr_enrich2_2xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_bcr_enrich1_2xspri_to_lbc_bcr_enrich2_2xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_bcr_enrich2_2xspri_to_lbc_bcr_dil_2.csv' do
        let(:csv_id) { 'hamilton_lbc_bcr_enrich2_2xspri_to_lbc_bcr_dil_2' }

        it_behaves_like 'a hamilton variable volume dilutions view'
      end

      context 'where csv id requested is hamilton_cherrypick_to_tcr_dilution1.csv' do
        let(:csv_id) { 'hamilton_cherrypick_to_tcr_dilution1' }

        it_behaves_like 'a hamilton cherrypick dilutions view'
      end

      context 'where csv id requested is hamilton_lbc_tcr_dil_1_to_lbc_tcr_enrich1_2xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_tcr_dil_1_to_lbc_tcr_enrich1_2xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_tcr_dil_2_to_lbc_tcr_post_lig_1xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_tcr_dil_2_to_lbc_tcr_post_lig_1xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_tcr_enrich1_2xspri_to_lbc_tcr_enrich2_2xspri.csv' do
        let(:csv_id) { 'hamilton_lbc_tcr_enrich1_2xspri_to_lbc_tcr_enrich2_2xspri' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lbc_tcr_enrich2_2xspri_to_lbc_tcr_dil_2.csv' do
        let(:csv_id) { 'hamilton_lbc_tcr_enrich2_2xspri_to_lbc_tcr_dil_2' }

        it_behaves_like 'a hamilton variable volume dilutions view'
      end

      context 'where csv id requested is hamilton_lds_al_lib_to_qc1.csv' do
        let(:csv_id) { 'hamilton_lds_al_lib_to_qc1' }
        let(:expected_template) { 'hamilton_plate_stamp_to_qc' }

        it_behaves_like 'a csv view'
      end

      context 'where csv id requested is hamilton_lds_al_lib_to_lds_al_lib_dil.csv' do
        let(:csv_id) { 'hamilton_lds_al_lib_to_lds_al_lib_dil' }

        it_behaves_like 'a hamilton variable volume dilutions with well diluents view'
      end

      context 'where csv id requested is hamilton_ltn_al_lib_to_qc1.csv' do
        let(:csv_id) { 'hamilton_ltn_al_lib_to_qc1' }
        let(:expected_template) { 'hamilton_plate_stamp_to_qc' }

        it_behaves_like 'a csv view'
      end

      context 'where csv id requested is hamilton_ltn_al_lib_to_ltn_al_lib_dil.csv' do
        let(:csv_id) { 'hamilton_ltn_al_lib_to_ltn_al_lib_dil' }

        it_behaves_like 'a hamilton variable volume dilutions with well diluents view'
      end
    end

    context 'where csv id requested is cellaca_input_file.csv' do
      let(:includes) { default_plate_includes }
      let(:csv_id) { 'cellaca_input_file' }
      let(:expected_template) { 'cellaca_input_file' }

      it_behaves_like 'a csv view'

      it 'assigns page 0 by default' do
        get :show, params: { id: csv_id, limber_plate_id: plate_barcode }, as: :csv
        expect(assigns(:page)).to be 0
      end

      it 'assigns page 1 if specified' do
        get :show, params: { id: csv_id, limber_plate_id: plate_barcode, page: '1' }, as: :csv
        expect(assigns(:page)).to be 1
      end

      it 'sets the correct filename' do
        page = 0
        get :show, params: { id: csv_id, limber_plate_id: plate_barcode, page: page }, as: :csv
        expect(
          @response.headers['Content-Disposition'].include?(
            "filename=\"cellaca_input_file_#{plate_barcode}_#{page + 1}.csv\""
          )
        ).to eq(true)
      end
    end
  end

  context 'where default' do
    let(:includes) { 'wells' }

    it 'returns 404 with unknown templates' do
      expect { get :show, params: { id: 'not_a_template', limber_plate_id: plate_barcode }, as: :csv }.to raise_error(
        ActionController::RoutingError,
        'Unknown template not_a_template'
      )
    end
  end
end
