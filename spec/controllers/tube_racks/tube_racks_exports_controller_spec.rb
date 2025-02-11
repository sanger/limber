# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TubeRacks::TubeRacksExportsController, type: :controller do
  let(:tube_rack_qc_includes) { 'racked_tubes.tube.receptacle.qc_results' }
  let(:tube_rack_selects) { { 'sample_metadata' => %w[tube_rack_barcode] } }
  let(:labware_uuid) { SecureRandom.uuid }

  let(:tube1_uuid) { SecureRandom.uuid }
  let(:tube2_uuid) { SecureRandom.uuid }
  let(:tube3_uuid) { SecureRandom.uuid }

  let(:tube1) { create :v2_tube, uuid: tube1_uuid, barcode_number: 1 }
  let(:tube2) { create :v2_tube, uuid: tube2_uuid, barcode_number: 2 }
  let(:tube3) { create :v2_tube, uuid: tube3_uuid, barcode_number: 3 }

  let!(:tube_rack) { create :tube_rack, barcode_number: 4, uuid: labware_uuid }

  let(:racked_tube1) { create :racked_tube, coordinate: 'A1', tube: tube1, tube_rack: tube_rack }
  let(:racked_tube2) { create :racked_tube, coordinate: 'B1', tube: tube2, tube_rack: tube_rack }
  let(:racked_tube3) { create :racked_tube, coordinate: 'C1', tube: tube3, tube_rack: tube_rack }

  let(:tube_rack_uuid) { tube_rack.uuid }

  RSpec.shared_examples 'a csv view' do
    it 'renders the view' do
      get :show, params: { id: csv_id, limber_tube_rack_id: tube_rack_uuid }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::TubeRack)
      expect(assigns(:tube_rack)).to be_a(Sequencescape::Api::V2::TubeRack)
      expect(response).to render_template(expected_template)
      assert_equal 'text/csv; charset=utf-8', @response.content_type
    end
  end

  context 'on generating a csv' do
    before do
      expect(Sequencescape::Api::V2).to receive(:tube_rack_with_custom_includes).with(
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

      it_behaves_like 'a csv view'
    end

    context 'where csv id requested is tube_rack_concentrations_nm.csv' do
      let(:includes) { tube_rack_qc_includes }
      let(:selects) { nil }
      let(:csv_id) { 'tube_rack_concentrations_nm' }
      let(:expected_template) { 'tube_rack_concentrations_nm' }

      it_behaves_like 'a csv view'
    end
  end

  context 'where default' do
    let(:includes) { 'tubes' }

    it 'returns 404 with unknown templates' do
      expect do
        get :show, params: { id: 'not_a_template', limber_tube_rack_id: tube_rack_uuid }, as: :csv
      end.to raise_error(ActionController::RoutingError, 'Unknown template not_a_template')
    end
  end
end
