# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/plates_controller'

RSpec.describe PlatesController, type: :controller do
  has_a_working_api

  let(:plate_uuid) { 'example-plate-uuid' }
  let(:v2_plate) { create :v2_plate, uuid: plate_uuid, purpose_uuid: 'stock-plate-purpose-uuid' }
  let(:wells_json) { json :well_collection }
  let(:plate_wells_request) { stub_api_get plate_uuid, 'wells', body: wells_json }
  let(:barcode_printers_request) { stub_api_get('barcode_printers', body: json(:barcode_printer_collection)) }
  let(:user_uuid) { SecureRandom.uuid }

  describe '#show' do
    before do
      create :stock_plate_config, uuid: 'stock-plate-purpose-uuid'
      stub_v2_plate(v2_plate, stub_search: false)
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
      assert_equal 'text/csv; charset=utf-8', @response.content_type
    end
  end

  describe '#update' do
    before do
      create :stock_plate_config, uuid: 'stock-plate-purpose-uuid'
      stub_api_get(plate_uuid, body: old_api_example_plate)
      stub_api_get(plate_uuid, 'wells', body: wells_json)
    end

    let(:old_api_example_plate) do
      json :plate, barcode_number: v2_plate.labware_barcode.number, uuid: plate_uuid, state: 'passed'
    end
    let!(:state_change_request) do
      stub_api_post('state_changes',
                    payload: {
                      'state_change' => {
                        user: user_uuid,
                        target: plate_uuid,
                        target_state: 'failed',
                        reason: 'Because testing',
                        customer_accepts_responsibility: true,
                        contents: nil
                      }
                    },
                    body: '{}') # We don't care about the response
    end

    it 'transitions the plate' do
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
          session: { user_uuid: user_uuid }
      expect(state_change_request).to have_been_made
      expect(response).to redirect_to(search_path)
    end
  end

  describe '#fail_wells' do
    let!(:state_change_request) do
      stub_api_post('state_changes',
                    payload: {
                      'state_change' => {
                        user: user_uuid,
                        target: plate_uuid,
                        contents: ['A1'],
                        target_state: 'failed',
                        reason: 'Individual Well Failure',
                        customer_accepts_responsibility: nil
                      }
                    },
                    body: '{}') # We don't care about the response
    end

    it 'fails the selected wells' do
      post :fail_wells,
           params: {
             id: plate_uuid,
             plate: { wells: { 'A1' => 1, 'B1' => 0 } }
           },
           session: { user_uuid: user_uuid }
      expect(state_change_request).to have_been_made
      expect(response).to redirect_to(limber_plate_path(plate_uuid))
    end
  end
end
