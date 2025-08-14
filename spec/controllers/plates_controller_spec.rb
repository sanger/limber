# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/plates_controller'

RSpec.describe PlatesController, type: :controller do
  has_a_working_api

  let(:plate_uuid) { 'example-plate-uuid' }
  let(:plate) { create :v2_plate, uuid: plate_uuid, purpose_uuid: 'stock-plate-purpose-uuid' }
  let(:barcode_printers_request) { stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3)) }
  let(:user_uuid) { SecureRandom.uuid }

  before { stub_v2_plate(plate, stub_search: false) }

  describe '#show' do
    before do
      create :stock_plate_config, uuid: 'stock-plate-purpose-uuid'
      barcode_printers_request
    end

    it 'shows the plate' do
      get :show, params: { id: plate_uuid }
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:presenter)).to be_a(Presenters::StockPlatePresenter)
    end

    it 'renders a csv' do
      get :show, params: { id: plate_uuid }, as: :csv
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Plate)
      expect(assigns(:presenter)).to be_a(Presenters::StockPlatePresenter)
      expect(@response.content_type).to eq('text/csv; charset=utf-8')
    end
  end

  describe '#update' do
    before { create :stock_plate_config, uuid: 'stock-plate-purpose-uuid' }

    let(:state_changes_attributes) do
      [
        {
          contents: nil,
          customer_accepts_responsibility: true,
          reason: 'Because testing',
          target_state: 'failed',
          target_uuid: plate_uuid,
          user_uuid: user_uuid
        }
      ]
    end

    it 'transitions the plate' do
      expect_state_change_creation

      put :update,
          params: {
            id: plate_uuid,
            state: 'failed',
            failed: {
              reason: 'Because testing',
              customer_accepts_responsibility: 'true'
            },
            purpose_uuid: 'stock-plate-purpose-uuid'
          },
          session: {
            user_uuid:
          }

      expect(response).to redirect_to(search_path)
    end
  end

  describe '#fail_wells' do
    let(:state_changes_attributes) do
      [
        {
          contents: ['A1'],
          customer_accepts_responsibility: nil,
          reason: 'Individual Well Failure',
          target_state: 'failed',
          target_uuid: plate_uuid,
          user_uuid: user_uuid
        }
      ]
    end

    it 'fails the selected wells' do
      expect_state_change_creation
      post :fail_wells, params: { id: plate_uuid, plate: { wells: { 'A1' => 1, 'B1' => 0 } } }, session: { user_uuid: }
      expect(response).to redirect_to(limber_plate_path(plate_uuid))
    end
  end

  describe '#process_mark_under_represented_wells' do
    let(:well_locations) { %w[A1 B2] }
    let(:wells) do
      well_locations.map do |location|
        build(:v2_well, location: location, aliquots: [build(:v2_aliquot, request: build(:request))])
      end
    end

    let(:plate_with_wells) do
      build(:v2_plate, uuid: plate_uuid, wells: wells)
    end

    before do
      # Stub the API to return our plate with wells
      allow(controller).to receive(:fetch_plate_with_requests).and_return(plate_with_wells)
      stub_request(:post, 'http://example.com:3000/api/v2/poly_metadata')
        .to_return(status: 200, body: '', headers: {})
    end

    context 'when wells are selected' do
      let(:expected_args) do
        wells.map do |well|
          {
            key: 'under_represented',
            value: 'true',
            relationships: { metadatable: well.aliquots.first.request }
          }
        end
      end

      it 'creates poly metadata for each selected well and redirects with notice' do
        expect_api_v2_posts('PolyMetadatum', expected_args)

        post :process_mark_under_represented_wells,
             params: {
               id: plate_uuid,
               plate: { wells: { 'A1' => '1', 'B2' => '1' } }
             }

        expect(response).to redirect_to(limber_plate_path(plate_uuid))
        expect(flash[:notice]).to eq(I18n.t('notices.wells_marked_under_represented'))
      end
    end

    context 'when no wells are selected' do
      it 'redirects with the no wells notice' do
        post :process_mark_under_represented_wells,
             params: { id: plate_uuid, plate: { wells: {} } }

        expect(response).to redirect_to(limber_plate_path(plate_uuid))
        expect(flash[:notice]).to eq(I18n.t('notices.no_wells_selected'))
      end
    end

    context 'when an error occurs' do
      before do
        allow(controller).to receive(:fetch_plate_with_requests).and_raise(StandardError, 'Unexpected error')
        allow(controller).to receive(:log_plate_error)
      end

      it 'redirects with an alert' do
        post :process_mark_under_represented_wells,
             params: { id: plate_uuid, plate: { wells: { 'A1' => '1' } } }

        expect(response).to redirect_to(limber_plate_path(plate_uuid))
        expect(flash[:alert]).to eq(I18n.t('errors.messages.mark_wells_under_represented_failed'))
      end
    end
  end
end
