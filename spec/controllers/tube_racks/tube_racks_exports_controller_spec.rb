# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TubeRacks::TubeRacksExportsController do
  let(:tube_rack_qc_includes) { 'racked_tubes.tube.receptacle.qc_results' }
  let(:labware_uuid) { SecureRandom.uuid }
  let(:tube_rack) { create :tube_rack, barcode_number: 4, uuid: labware_uuid }
  let(:tube_rack_uuid) { tube_rack.uuid }

  RSpec.shared_examples 'a tube rack csv view' do
    context 'when the tube rack is requested' do
      before { get :show, params: { id: csv_id, limber_tube_rack_id: tube_rack_uuid }, as: :csv }

      it 'returns a HTTP OK response' do
        expect(response).to have_http_status(:ok)
      end

      it 'assigns the labware to a tube rack object' do
        expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::TubeRack)
      end

      it 'assigns the tube rack to a tube rack object' do
        expect(assigns(:tube_rack)).to be_a(Sequencescape::Api::V2::TubeRack)
      end

      it 'renders the template' do
        expect(response).to render_template(expected_template)
      end

      it 'returns the correct content type' do
        expect(response.content_type).to eq('text/csv; charset=utf-8')
      end
    end
  end

  context 'when generating a csv' do
    before do
      allow(Sequencescape::Api::V2).to receive(:tube_rack_with_custom_includes).with(
        includes,
        selects,
        uuid: tube_rack_uuid
      ).and_return(tube_rack)
    end

    context 'where csv id requested is tube_rack_concentrations_ngul.csv' do
      let(:includes) { tube_rack_qc_includes }
      let(:selects) { nil }
      let(:csv_id) { 'tube_rack_concentrations_ngul' }
      let(:expected_template) { 'tube_rack_concentrations_ngul' }

      it_behaves_like 'a tube rack csv view'
    end

    context 'where csv id requested is tube_rack_concentrations_nm.csv' do
      let(:includes) { tube_rack_qc_includes }
      let(:selects) { nil }
      let(:csv_id) { 'tube_rack_concentrations_nm' }
      let(:expected_template) { 'tube_rack_concentrations_nm' }

      it_behaves_like 'a tube rack csv view'
    end
  end

  context 'where default' do
    it 'returns 404 with unknown templates' do
      expect do
        get :show, params: { id: 'not_a_template', limber_tube_rack_id: tube_rack_uuid }, as: :csv
      end.to raise_error(ActionController::RoutingError, 'Unknown template not_a_template')
    end
  end

  context 'when finding ancestor tubes' do
    context 'when ancestor_tube_purpose is not present' do
      let(:csv_id) { 'tube_rack_concentrations_ngul' }
      let(:includes) { tube_rack_qc_includes }
      let(:selects) { nil }
      let(:response) { get :show, params: { id: csv_id, limber_tube_rack_id: tube_rack_uuid }, as: :csv }

      before do
        allow(Sequencescape::Api::V2).to receive(:tube_rack_with_custom_includes).with(
          includes,
          selects,
          uuid: tube_rack_uuid
        ).and_return(tube_rack)
      end

      it 'returns an HTTP OK response' do
        expect(response).to have_http_status(:ok)
      end

      it 'is nil' do
        expect(assigns(:ancestor_tubes)).to be_nil
      end
    end

    context 'when ancestor_tube_purpose is present and matching ancestors exist' do
      let(:csv_id) { 'hamilton_lrc_pbmc_bank_to_lrc_bank_seq_and_spare' }
      let(:includes) { 'racked_tubes.tube' }
      let(:selects) { nil }
      let(:ancestor_purpose_name) { 'LRC Blood Vac' }
      let(:ancestor_tubes) { create_list(:v2_tube, 3, purpose: ancestor_purpose_name) }
      let(:ancestor_tubes_sample_hash) { ancestor_tubes.index_by { |tube| tube.aliquots.first.sample.uuid } }

      before do
        allow(Sequencescape::Api::V2).to receive(:tube_rack_with_custom_includes).with(
          includes,
          selects,
          uuid: tube_rack_uuid
        ).and_return(tube_rack)

        ancestor_tubes.each do |ancestor_tube|
          allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(uuid: ancestor_tube.uuid).and_return(
            ancestor_tube
          )
        end

        asset_ancestors =
          ancestor_tubes.map { |ancestor_tube| double('Sequencescape::Api::V2::Asset', uuid: ancestor_tube.uuid) }

        allow(tube_rack).to receive_message_chain(:ancestors, :where).with(
          purpose_name: ancestor_purpose_name
        ).and_return(asset_ancestors)
      end

      it 'returns 200 OK' do
        get :show, params: { id: csv_id, limber_tube_rack_id: tube_rack_uuid }, as: :csv
        expect(response).to have_http_status(:ok)
      end

      it 'returns the ancestors' do
        get :show, params: { id: csv_id, limber_tube_rack_id: tube_rack_uuid }, as: :csv
        expect(assigns(:ancestor_tubes)).to eq(ancestor_tubes_sample_hash)
      end
    end
  end
end
