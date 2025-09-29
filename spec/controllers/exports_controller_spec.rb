# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/plates_controller'

RSpec.describe ExportsController, type: :controller do
  let(:default_plate_includes) { 'wells' }
  let(:well_qc_includes) { 'wells.qc_results' }
  let(:well_qc_sample_includes) { 'wells.qc_results,wells.aliquots.sample.sample_metadata' }
  let(:well_with_request_metadata_includes) do
    'wells.qc_results,wells.aliquots.sample.sample_metadata,wells.aliquots.request.poly_metadata'
  end
  let(:well_src_asset_includes) { 'wells.transfer_requests_as_target.source_asset' }
  let(:plate) { create :plate, barcode_number: 1 }
  let(:plate_barcode) { 'DN1S' }

  RSpec.shared_examples 'a csv view' do
    it 'renders the view' do
      get :show, params: { id: csv_id, plate_id: plate_barcode }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:plate)).to be_a(Sequencescape::Api::V2::Plate)
      expect(response).to render_template(expected_template)
      expect(@response.content_type).to eq('text/csv; charset=utf-8')
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

  RSpec.shared_examples 'a hamilton variable volume dilutions with request diluents view' do
    let(:expected_template) { 'hamilton_variable_volume_dilutions_with_request_diluents' }

    it_behaves_like 'a csv view'
  end

  RSpec.shared_examples 'a hamilton cherrypick dilutions view' do
    let(:expected_template) { 'hamilton_cherrypick_dilutions' }

    it_behaves_like 'a csv view'
  end

  context 'on generating a csv' do
    before do
      expect(Sequencescape::Api::V2).to receive(:plate_with_custom_includes).with(
        includes,
        barcode: plate_barcode
      ).and_return(plate)
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

    context 'where csv id requested is duplex_seq_al_lib_concentrations_for_customer.csv' do
      let(:includes) { well_qc_sample_includes }
      let(:csv_id) { 'duplex_seq_al_lib_concentrations_for_customer' }
      let(:expected_template) { 'duplex_seq_al_lib_concentrations_for_customer' }

      it_behaves_like 'a csv view'
    end

    context 'where csv id requested is duplex_seq_pcr_xp_concentrations_for_custom_pooling.csv' do
      let(:includes) { well_qc_includes }
      let(:csv_id) { 'duplex_seq_pcr_xp_concentrations_for_custom_pooling' }
      let(:expected_template) { 'duplex_seq_pcr_xp_concentrations_for_custom_pooling' }

      it_behaves_like 'a csv view'
    end

    context 'where csv id requested is targeted_nanoseq_al_lib_concentrations_for_customer.csv' do
      let(:includes) { well_qc_sample_includes }
      let(:csv_id) { 'targeted_nanoseq_al_lib_concentrations_for_customer' }
      let(:expected_template) { 'targeted_nanoseq_al_lib_concentrations_for_customer' }

      it_behaves_like 'a csv view'
    end

    context 'where csv id requested is targeted_nanoseq_pcr_xp_merged_file.csv' do
      let(:includes) { well_with_request_metadata_includes }
      let(:csv_id) { 'targeted_nanoseq_pcr_xp_merged_file' }
      let(:expected_template) { 'targeted_nanoseq_pcr_xp_merged_file' }

      it_behaves_like 'a csv view'
    end

    context 'where csv id requested is lcmb_pcr_xp_concentrations_for_custom_pooling.csv' do
      let(:includes) { 'wells.qc_results,wells.aliquots,wells.aliquots.sample' }
      let(:csv_id) { 'lcmb_pcr_xp_concentrations_for_custom_pooling' }
      let(:expected_template) { 'lcmb_pcr_xp_concentrations_for_custom_pooling' }

      it_behaves_like 'a csv view'
    end

    context 'where csv id requested is kinnex_prep_plate_export.csv' do
      let(:includes) { 'wells.downstream_tubes' }
      let(:csv_id) { 'kinnex_prep_plate_export' }
      let(:expected_template) { 'kinnex_prep_plate_export' }

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
        let(:includes) { 'wells.transfer_requests_as_target.source_asset,wells.aliquots.request.poly_metadata' }
        let(:csv_id) { 'hamilton_ltn_al_lib_to_ltn_al_lib_dil' }

        it_behaves_like 'a hamilton variable volume dilutions with request diluents view'
      end

      context 'where csv id requested is hamilton_lrc_gem_x_5p_cherrypick_to_lrc_gem_x_5p_ge_dil.csv' do
        let(:csv_id) { 'hamilton_lrc_gem_x_5p_cherrypick_to_lrc_gem_x_5p_ge_dil' }

        it_behaves_like 'a hamilton fixed volume dilutions view'
      end

      context 'where csv id requested is hamilton_lrc_gemx_5p_bcr_dil_1_to_lrc_gemx_5p_bcr_enrich1.csv' do
        let(:csv_id) { 'hamilton_lrc_gemx_5p_bcr_dil_1_to_lrc_gemx_5p_bcr_enrich1' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lrc_gemx_5p_bcr_enrich1_to_lrc_gemx_5p_bcr_enrich2.csv' do
        let(:csv_id) { 'hamilton_lrc_gemx_5p_bcr_enrich1_to_lrc_gemx_5p_bcr_enrich2' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lrc_gemx_5p_bcr_enrich2_to_lrc_gemx_5p_bcr_dil_2.csv' do
        let(:csv_id) { 'hamilton_lrc_gemx_5p_bcr_enrich2_to_lrc_gemx_5p_bcr_dil_2' }

        it_behaves_like 'a hamilton fixed volume dilutions view'
      end

      context 'where csv id requested is hamilton_lrc_gemx_5p_bcr_dil_2_to_lrc_gemx_5p_bcr_post_lig.csv' do
        let(:csv_id) { 'hamilton_lrc_gemx_5p_bcr_dil_2_to_lrc_gemx_5p_bcr_post_lig' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lrc_gemx_5p_tcr_dil_1_to_lrc_gemx_5p_tcr_enrich1.csv' do
        let(:csv_id) { 'hamilton_lrc_gemx_5p_tcr_dil_1_to_lrc_gemx_5p_tcr_enrich1' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lrc_gemx_5p_tcr_enrich1_to_lrc_gemx_5p_tcr_enrich2.csv' do
        let(:csv_id) { 'hamilton_lrc_gemx_5p_tcr_enrich1_to_lrc_gemx_5p_tcr_enrich2' }

        it_behaves_like 'a hamilton plate stamp view'
      end

      context 'where csv id requested is hamilton_lrc_gemx_5p_tcr_enrich2_to_lrc_gemx_5p_tcr_dil_2.csv' do
        let(:csv_id) { 'hamilton_lrc_gemx_5p_tcr_enrich2_to_lrc_gemx_5p_tcr_dil_2' }

        it_behaves_like 'a hamilton fixed volume dilutions view'
      end

      context 'where csv id requested is hamilton_lrc_gemx_5p_tcr_dil_2_to_lrc_gemx_5p_tcr_post_lig.csv' do
        let(:csv_id) { 'hamilton_lrc_gemx_5p_tcr_dil_2_to_lrc_gemx_5p_tcr_post_lig' }

        it_behaves_like 'a hamilton plate stamp view'
      end
    end

    context 'where csv id requested is cellaca_input_file.csv' do
      let(:includes) { default_plate_includes }
      let(:csv_id) { 'cellaca_input_file' }
      let(:expected_template) { 'cellaca_input_file' }

      it_behaves_like 'a csv view'

      it 'assigns page 0 by default' do
        get :show, params: { id: csv_id, plate_id: plate_barcode }, as: :csv
        expect(assigns(:page)).to be 0
      end

      it 'assigns page 1 if specified' do
        get :show, params: { id: csv_id, plate_id: plate_barcode, page: '1' }, as: :csv
        expect(assigns(:page)).to be 1
      end

      it 'sets the correct filename' do
        page = 0
        get :show, params: { id: csv_id, plate_id: plate_barcode, page: page }, as: :csv
        expect(
          @response.headers['Content-Disposition'].include?(
            "filename=\"cellaca_input_file_#{plate_barcode}_#{page + 1}.csv\""
          )
        ).to be(true)
      end
    end
  end

  context 'where default' do
    it 'returns 404 with unknown templates' do
      expect { get :show, params: { id: 'not_a_template', plate_id: plate_barcode }, as: :csv }.to raise_error(
        ActionController::RoutingError,
        'Unknown template not_a_template'
      )
    end
  end

  context 'with multiple ancestor plates' do
    # Set up three ancestor plates for this test.
    # example_ancestor_purpose is the purpose of the ancestor plates.
    # The purpose name is used for ancestor_purpose in the exports configuration fixture.
    #
    # Fixtures:
    # spec/fixtures/config/multiple_ancestor_plates.yml is the exports configuration file.
    # spec/fixtures/app/views/exports/multiple_ancestor_plates.csv.erb is the view that generates the exports.
    #
    # multiple_ancestor_plates_configured is the id of an export in exports.yml
    # multiple_ancestor_plates_not_configured is the id of an export in exports.yml
    # multiple_ancestor_plates is the view name for both exports set in exports.yml

    let(:ancestor_purpose_name) { 'example_ancestor_purpose' }
    let(:ancestor_purpose) { create(:purpose, name: ancestor_purpose_name) }
    let(:ancestor_plates) { create_list(:plate, 3, purpose: ancestor_purpose) }

    let(:exports_path) { 'spec/fixtures/config/exports/multiple_ancestor_plates.yml' }
    let(:config) { YAML.load_file(exports_path) }
    let(:export) { Export.new(config.fetch(csv_id)) } # csv_id specified by the individual test

    before do
      # Make the controller to receive the plate.
      # NB. Uses plate_includes if specified in the export configuration.
      allow(Sequencescape::Api::V2).to receive(:plate_with_custom_includes).with(
        export.plate_includes,
        barcode: plate_barcode
      ).and_return(plate)

      # Make the controller to use the export loaded from fixture config.
      allow(subject).to receive(:export).and_return(export)

      # Make the controller to find the fixture template for rendering.
      subject.prepend_view_path('spec/fixtures/app/views')

      # Stub the ancestors query to return ancestor plates.
      # NB. The result is an array of Sequencescape::Api::V2::Asset objects
      # with the ancestor plate ids.
      asset_ancestors =
        ancestor_plates.map { |ancestor_plate| double('Sequencescape::Api::V2::Asset', id: ancestor_plate.id) }

      allow(plate).to receive_message_chain(:ancestors, :where).with(purpose_name: export.ancestor_purpose).and_return(
        asset_ancestors
      )

      # Stub the plate_with_custom_includes query to return the first ancestor plate.
      # NB. This stub is required to make the other methods in the show controller
      # action not to fail when they try to receive the first ancestor plate.
      allow(Sequencescape::Api::V2).to receive(:plate_with_custom_includes).with(
        export.plate_includes,
        id: asset_ancestors.first.id
      ).and_return(ancestor_plates.first)

      # Stub the plate query to return ancestor plates.
      builder = double('JsonApiClient::Query::Builder')
      allow(Sequencescape::Api::V2::Plate).to receive(:includes).with(export.plate_includes).and_return(builder)
      allow(builder).to receive(:find).with({ id: asset_ancestors.map(&:id) }).and_return(ancestor_plates)
    end

    context 'when ancestor plate is configured' do
      let(:csv_id) { 'multiple_ancestor_plates_configured' }

      it 'assigns @ancestor_plate_list to the list of ancestor plates' do
        # The export controller's show action should assign @ancestor_plate_list
        # to an array of ancestor plates.
        get :show, params: { id: csv_id, plate_id: plate_barcode }, as: :csv
        expect(assigns(:ancestor_plate_list)).to eq(ancestor_plates)
      end

      it 'renders the view with @ancestor_plate_list' do
        # The export controller's show action should render the view with
        # @ancestor_plate_list.
        get :show, params: { id: csv_id, plate_id: plate_barcode }, as: :csv

        expect(response).to render_template('exports/multiple_ancestor_plates')

        output = [['Plate Barcode', plate.barcode.human], ['Ancestor Barcode', 'Ancestor Purpose']]
        ancestor_plates.each { |ancestor_plate| output << [ancestor_plate.barcode.human, ancestor_purpose_name] }

        output = "#{output.map { |line| line.join(',') }.join("\n")}\n"

        expect(response.body).to eq(output)
      end
    end

    context 'when ancestor plate is not configured' do
      let(:csv_id) { 'multiple_ancestor_plates_not_configured' }

      it 'assigns @ancestor_plate_list to an empty array' do
        # The export controller's show action should assign @ancestor_plate_list
        # to an empty array if the ancestor plate is not configured.
        get :show, params: { id: csv_id, plate_id: plate_barcode }, as: :csv
        expect(assigns(:ancestor_plate_list)).to eq([])
      end

      it 'renders the view with an empty @ancestor_plate_list' do
        # The export controller's show action should render the view with an empty
        # @ancestor_plate_list if the ancestor plate is not configured.

        get :show, params: { id: csv_id, plate_id: plate_barcode }, as: :csv
        expect(response).to render_template('exports/multiple_ancestor_plates')

        output = [['Plate Barcode', plate.barcode.human], ['Ancestor Barcode', 'Ancestor Purpose']]
        output = "#{output.map { |line| line.join(',') }.join("\n")}\n"

        expect(response.body).to eq(output) # empty ancestor plate table
      end
    end
  end
end
