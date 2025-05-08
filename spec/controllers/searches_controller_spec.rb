# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  include FeatureHelpers

  has_a_working_api

  let(:plate_uuid) { 'example-plate-uuid' }
  let(:barcode_printers_request) { stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3)) }
  let(:user_uuid) { SecureRandom.uuid }
  let(:uuid) { SecureRandom.uuid }

  describe '#new' do
    it 'returns 200' do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#search' do
    let(:barcode) { '12345' }

    before { stub_barcode_search(barcode, labware) }

    context 'for a plate' do
      let(:labware) { create :labware_plate, uuid: }

      it 'redirects to the found labware' do
        post :create, params: { plate_barcode: barcode }
        expect(response).to redirect_to(limber_plate_path(uuid))
      end
    end

    context 'for a tube' do
      let(:labware) { create :labware_tube, uuid: }

      it 'redirects to the found labware' do
        post :create, params: { plate_barcode: barcode }
        expect(response).to redirect_to(limber_tube_path(uuid))
      end
    end

    context 'for a tube rack' do
      let(:labware) { create :labware_tube_rack, uuid: }

      it 'redirects to the found labware' do
        post :create, params: { plate_barcode: barcode }
        expect(response).to redirect_to(limber_tube_rack_path(uuid))
      end
    end
  end

  context 'configured plates and tubes' do
    before do
      create(:purpose_config, uuid: 'uuid-1')
      create(:minimal_purpose_config, uuid: 'uuid-2')
      create(:tube_config, uuid: 'uuid-3')
      create(:tube_config, uuid: 'uuid-4')
    end

    let(:expected_search) { stub_search_and_multi_result(search_name, { 'search' => search_parameters }, [result]) }

    describe '#ongoing_plates' do
      let(:search_name) { 'Find plates' }
      let(:result) { associated :plate }

      context 'without parameters' do
        let(:search_parameters) do
          {
            states: %w[pending started passed qc_complete failed cancelled],
            plate_purpose_uuids: %w[uuid-1 uuid-2],
            show_my_plates_only: false,
            include_used: false,
            page: 1
          }
        end

        it 'finds all plates' do
          expected_search
          get :ongoing_plates
          expect(expected_search).to have_been_made.once
        end
      end

      context 'with parameters' do
        let(:search_parameters) do
          {
            states: %w[pending started passed qc_complete failed cancelled],
            plate_purpose_uuids: ['uuid-1'],
            show_my_plates_only: true,
            include_used: true,
            page: 1
          }
        end

        it 'finds specified plates' do
          expected_search
          get :ongoing_plates,
              params: {
                ongoing_plate: {
                  purposes: ['uuid-1'],
                  show_my_plates_only: '1',
                  include_used: '1'
                }
              }
          expect(expected_search).to have_been_made.once
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe '#ongoing_tubes' do
      let(:search_name) { 'Find tubes' }
      let(:result) { associated :tube }

      context 'without parameters' do
        let(:search_parameters) do
          {
            states: %w[pending started passed qc_complete failed cancelled],
            tube_purpose_uuids: %w[uuid-3 uuid-4],
            include_used: false,
            page: 1
          }
        end

        it 'finds all tubes' do
          expected_search
          get :ongoing_tubes
          expect(expected_search).to have_been_made.once
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with parameters' do
        let(:search_parameters) do
          {
            states: %w[pending started passed qc_complete failed cancelled],
            tube_purpose_uuids: ['uuid-3'],
            include_used: true,
            page: 1
          }
        end

        it 'finds specified tubes' do
          expected_search
          get :ongoing_tubes, params: { ongoing_tube: { purposes: ['uuid-3'], include_used: '1' } }
          expect(expected_search).to have_been_made.once
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
