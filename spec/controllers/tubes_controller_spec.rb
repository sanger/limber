# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/tubes_controller'

RSpec.describe TubesController, type: :controller do
  has_a_working_api

  let(:tube_uuid) { 'example-tube-uuid' }
  let(:tube_json) { json :tube, uuid: tube_uuid, purpose_uuid: 'stock-tube-purpose-uuid' }
  let(:v2_tube) { create :v2_tube, uuid: tube_uuid, purpose_uuid: 'stock-tube-purpose-uuid' }
  let(:wells_json) { json :well_collection }
  let(:tube_request) { stub_api_get tube_uuid, body: tube_json }
  let(:tube_wells_request) { stub_api_get tube_uuid, 'wells', body: wells_json }
  let(:barcode_printers_request) { stub_api_get('barcode_printers', body: json(:barcode_printer_collection)) }
  let(:user_uuid) { SecureRandom.uuid }

  describe '#show' do
    before do
      create :tube_config, uuid: 'stock-tube-purpose-uuid'
      stub_v2_tube(v2_tube, stub_search: false)
      barcode_printers_request
    end

    it 'shows the tube' do
      get :show, params: { id: tube_uuid }
      expect(response).to have_http_status(:ok)
      expect(assigns(:labware)).to be_a(Sequencescape::Api::V2::Tube)
      expect(assigns(:presenter)).to be_a(Presenters::TubePresenter)
    end
  end

  describe '#update' do
    before do
      create :tube_config, uuid: 'stock-tube-purpose-uuid'
      tube_request
    end

    let!(:state_change_request) do
      stub_api_post('state_changes',
                    payload: {
                      'state_change' => {
                        user: user_uuid,
                        target: tube_uuid,
                        target_state: 'cancelled',
                        reason: 'Because testing',
                        customer_accepts_responsibility: true,
                        contents: nil
                      }
                    },
                    body: '{}') # We don't care about the response
    end

    it 'transitions the tube' do
      put :update,
          params: {
            id: tube_uuid,
            state: 'cancelled',
            cancelled: {
              reason: 'Because testing',
              customer_accepts_responsibility: true
            },
            purpose_uuid: 'stock-tube-purpose-uuid'
          },
          session: { user_uuid: user_uuid }
      expect(state_change_request).to have_been_made
      expect(response).to redirect_to(search_path)
    end
  end
end
