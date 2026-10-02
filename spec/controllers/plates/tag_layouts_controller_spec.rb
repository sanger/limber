# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plates::TagLayoutsController do
  let(:plate_uuid) { SecureRandom.uuid }
  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { 'tagged-in-place-purpose-uuid' }
  let(:purpose_name) { 'Tagged in place purpose' }
  let(:state) { 'processed_1' }
  let(:plate) do
    create :plate, uuid: plate_uuid, state: state, purpose_uuid: purpose_uuid, purpose_name: purpose_name,
                   pool_sizes: [2]
  end

  before do
    create :purpose_config,
           uuid: purpose_uuid,
           name: purpose_name,
           presenter_class: 'Presenters::UltimaConversionPresenter',
           tags_per_well: 1
    create :purpose_config, uuid: 'child-purpose-uuid', name: 'Child purpose'
    create :pipeline, relationships: { purpose_name => 'Child purpose' }
    stub_plate(plate, stub_search: false)
  end

  describe '#new' do
    render_views

    context 'when tags can be added' do
      before { get :new, params: { plate_id: plate_uuid }, session: { user_uuid: } }

      it 'renders the tagging page' do
        expect(response).to have_http_status(:ok)
      end

      it 'mounts the manual Ultima component' do
        expect(response.body).to include('id=\'manual-ultima-tagged-plate-page\'')
      end

      it 'filters tag sets by Ultima adapter type' do
        expect(response.body).to include('data-tag-group-adapter-type-name-filter="Ultima"')
      end

      it 'enables in-place tagging' do
        expect(response.body).to include('data-in-place="true"')
      end

      it 'submits to the plate tag layouts endpoint' do
        expect(response.body).to include("data-target-url=\"#{plate_tag_layouts_path(plate_uuid)}\"")
      end
    end

    context 'when tags cannot be added' do
      let(:state) { 'processed_2' }

      it 'redirects to the plate' do
        get :new, params: { plate_id: plate_uuid }, session: { user_uuid: }
        expect(response).to redirect_to(plate_path(plate_uuid))
      end
    end
  end

  describe '#create' do
    let(:tag_layout) do
      {
        tag_group_uuid: 'tag-group-uuid',
        tag2_group_uuid: '',
        direction: 'column',
        walking_by: 'manual by plate',
        initial_tag: '0',
        tags_per_well: '1'
      }
    end
    let(:state_changer) { instance_double(StateChangers::PlateStateChanger, move_to!: true) }

    before do
      allow(Sequencescape::Api::V2::TagLayout).to receive(:create!)
      allow(StateChangers::PlateStateChanger).to receive(:new).with(plate_uuid, user_uuid).and_return(state_changer)
    end

    def post_tag_layout
      post :create, params: { plate_id: plate_uuid, plate: { tag_layout: } }, session: { user_uuid: }, format: :json
    end

    context 'when tags can be added' do
      before { post_tag_layout }

      it 'adds the tags to the plate itself' do
        expect(Sequencescape::Api::V2::TagLayout).to have_received(:create!).with(
          'tag_group_uuid' => 'tag-group-uuid',
          'direction' => 'column',
          'walking_by' => 'manual by plate',
          'initial_tag' => '0',
          'tags_per_well' => '1',
          plate_uuid: plate_uuid,
          user_uuid: user_uuid
        )
      end

      it 'moves the plate to the tagged state' do
        expect(state_changer).to have_received(:move_to!).with('processed_2', 'Tags added')
      end

      it 'responds with the plate to redirect to' do
        expect(response.parsed_body['redirect']).to eq(plate_path(plate_uuid))
      end
    end

    context 'when tags cannot be added' do
      let(:state) { 'processed_2' }

      before { post_tag_layout }

      it 'does not add the tags' do
        expect(Sequencescape::Api::V2::TagLayout).not_to have_received(:create!)
      end

      it 'responds with an error' do
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
