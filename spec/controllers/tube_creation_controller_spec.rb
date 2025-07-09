# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/tubes_controller'

RSpec.describe TubeCreationController, type: :controller do
  has_a_working_api
  include FeatureHelpers

  context 'for a tube with a custom-form' do
    # TODO: We currently have no tube forms with custom forms
  end

  let(:parent_uuid) { 'parent-uuid' }
  let(:child_purpose_uuid) { 'child-purpose-uuid' }
  let(:user_uuid) { 'user_uuid' }
  let(:child_uuid) { 'child_uuid' }

  context 'for a tube with an automatic form' do
    before do
      create :purpose_config, creator_class: 'LabwareCreators::PooledTubesBySubmission', uuid: child_purpose_uuid
    end

    describe '#new' do
      it 'creates a tube from a tube parent' do
        get :new, params: { tube_id: parent_uuid, purpose_uuid: child_purpose_uuid }, session: { user_uuid: }
        expect(response).to render_template('new')
        expect(assigns(:labware_creator).parent_uuid).to eq(parent_uuid)
        expect(assigns(:labware_creator).user_uuid).to eq(user_uuid)
        expect(assigns(:labware_creator).purpose_uuid).to eq(child_purpose_uuid)
      end

      it 'creates a tube from a plate parent' do
        get :new, params: { plate_id: parent_uuid, purpose_uuid: child_purpose_uuid }, session: { user_uuid: }
        expect(response).to render_template('new')
        expect(assigns(:labware_creator).parent_uuid).to eq(parent_uuid)
        expect(assigns(:labware_creator).user_uuid).to eq(user_uuid)
        expect(assigns(:labware_creator).purpose_uuid).to eq(child_purpose_uuid)
      end
    end

    describe '#create' do
      before do
        expect_any_instance_of(LabwareCreators::PooledTubesBySubmission).to receive(:save).and_return(true)
        expect_any_instance_of(LabwareCreators::PooledTubesBySubmission).to receive(:redirection_target).and_return(
          build(:tube, uuid: child_uuid)
        )
      end

      context 'from a tube parent' do
        it 'creates a tube' do
          post :create,
               params: {
                 tube_id: parent_uuid,
                 tube: {
                   purpose_uuid: child_purpose_uuid
                 }
               },
               session: {
                 user_uuid:
               }
          expect(response).to redirect_to("#{tube_path(child_uuid)}#relatives_tab")
          expect(assigns(:labware_creator).parent_uuid).to eq(parent_uuid)
          expect(assigns(:labware_creator).user_uuid).to eq(user_uuid)
          expect(assigns(:labware_creator).purpose_uuid).to eq(child_purpose_uuid)
        end
      end

      context 'from a plate parent' do
        it 'creates a tube' do
          post :create,
               params: {
                 plate_id: parent_uuid,
                 tube: {
                   purpose_uuid: child_purpose_uuid
                 }
               },
               session: {
                 user_uuid:
               }
          expect(response).to redirect_to("#{tube_path(child_uuid)}#relatives_tab")
          expect(assigns(:labware_creator).parent_uuid).to eq(parent_uuid)
          expect(assigns(:labware_creator).user_uuid).to eq(user_uuid)
          expect(assigns(:labware_creator).purpose_uuid).to eq(child_purpose_uuid)
        end
      end
    end
  end
end
