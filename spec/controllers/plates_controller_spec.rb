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

      expect(response).to redirect_to(plate_path(plate_uuid))
    end
  end
end
