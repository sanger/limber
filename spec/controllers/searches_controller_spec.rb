# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  include FeatureHelpers

  has_a_working_api

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

  describe 'POST #create' do
    context 'when a valid plate barcode is provided' do
      let(:barcode) { 'ABC123' }

      before { allow(controller).to receive(:find_labware).with(barcode).and_return('/labware/ABC123') }

      it 'redirects to the found labware for HTML format' do
        post :create, params: { plate_barcode: barcode }, format: :html
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to('/labware/ABC123')
      end

      it 'returns a JSON response with the labware location' do
        post :create, params: { plate_barcode: barcode }, format: :json
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to('/labware/ABC123')
      end
    end

    context 'when no plate barcode is provided' do
      it 'renders the new template with an error message for HTML' do
        post :create, params: { plate_barcode: '' }, format: :html
        expect(response).to have_http_status(:not_found)
        expect(response).to render_template(:new)
        expect(flash[:error]).to eq('You have not supplied a labware barcode')
      end

      it 'returns a JSON error response' do
        post :create, params: { plate_barcode: '' }, format: :json
        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body).to eq('error' => 'You have not supplied a labware barcode')
      end
    end
  end

  context 'configured plates and tubes' do
    before do
      create(:purpose_config, name: 'purpose-config', uuid: 'purpose-config-uuid')
      create(:minimal_purpose_config, name: 'minimal-purpose-config', uuid: 'minimal-purpose-config-uuid')
      create(:tube_config, name: 'tube-config-3', uuid: 'uuid-3')
      create(:tube_config, name: 'tube-config-4', uuid: 'uuid-4')
    end

    let(:expected_search) do
      stub_find_all_with_pagination(api_class, search_parameters, { page: 1, per_page: 30 }, [result])
    end

    describe '#ongoing_plates' do
      let(:api_class) { :plates }
      let(:result) { create :v2_plate }

      context 'without parameters' do
        let(:search_parameters) do
          { state: %w[pending started passed qc_complete failed cancelled], purpose_name: [], include_used: false }
        end

        it 'finds all plates' do
          expected_search
          get :ongoing_plates
          expected_search.once
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with parameters' do
        let(:search_parameters) do
          { state: %w[pending started passed qc_complete failed cancelled], purpose_name: [], include_used: true }
        end

        it 'finds specified plates' do
          expected_search
          get :ongoing_plates,
              params: {
                ongoing_plate: {
                  purpose_name: %w[purpose-config minimal-purpose-config],
                  include_used: '1'
                }
              }
          expected_search.once
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe '#ongoing_tubes' do
      let(:api_class) { :tubes }
      let(:result) { create :v2_tube }

      context 'without parameters' do
        let(:search_parameters) do
          {
            state: %w[pending started passed qc_complete failed cancelled],
            purpose_name: %w[tube-config-3 tube-config-4],
            include_used: false
          }
        end

        it 'finds all tubes' do
          expected_search
          get :ongoing_tubes
          expected_search.once
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with parameters' do
        let(:search_parameters) do
          {
            state: %w[pending started passed qc_complete failed cancelled],
            purpose_name: ['tube-config-3'],
            include_used: true
          }
        end

        it 'finds specified tubes' do
          expected_search
          get :ongoing_tubes, params: { ongoing_tube: { purposes: ['uuid-3'], include_used: '1' } }
          expected_search.once
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
