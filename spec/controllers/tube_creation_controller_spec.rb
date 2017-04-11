# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/tubes_controller'

describe TubeCreationController, type: :controller do
  has_a_working_api
  include FeatureHelpers

  # Note: This controller shows incorrect behaviour.
  # The new action should be idempotent.
  # Also, we should strongly consider unifying the
  # plate ans tube creation controllers.

  context 'for a tube with a custom-form' do
    # TODO: We currently have no tube forms with custom forms
  end

  let(:parent_uuid) { 'parent-uuid' }
  let(:child_purpose_uuid) { 'child-purpose-uuid' }
  let(:user_uuid) { 'user_uuid' }
  let(:child_uuid) { 'child_uuid' }

  context 'for a tube with an automatic form' do
    setup do
      Settings.purposes[child_purpose_uuid] = {
        form_class: 'LabwareCreators::PoolTubesBySubmission'
      }
    end

    describe '#new' do
      # This action behaves incorrectly. Its behaviour belongs on create.
      # New should be idempotent, and falls out of the standard workflow for
      # automated forms. The correct behaviour probably should be
      # rendering a dirt simple form which triggers a post request with the
      # appropriate parameters. However we should try and send the user
      # direct to #create.

      setup do
        expect_any_instance_of(LabwareCreators::PoolTubesBySubmission).to receive(:save!).and_return(true)
        expect_any_instance_of(LabwareCreators::PoolTubesBySubmission).to receive(:child).and_return(build(:tube, uuid: child_uuid))
      end

      context 'from a tube parent' do
        it 'creates a tube' do
          get :new, params: { limber_plate_id: parent_uuid, purpose_uuid: child_purpose_uuid }, session: { user_uuid: user_uuid }
          expect(response).to redirect_to(limber_tube_path(child_uuid))
          expect(assigns(:creation_form).parent_uuid).to eq(parent_uuid)
          expect(assigns(:creation_form).user_uuid).to eq(user_uuid)
          expect(assigns(:creation_form).purpose_uuid).to eq(child_purpose_uuid)
        end
      end

      context 'from a plate parent' do
        it 'creates a tube' do
          get :new, params: { limber_tube_id: parent_uuid, purpose_uuid: child_purpose_uuid }, session: { user_uuid: user_uuid }
          expect(response).to redirect_to(limber_tube_path(child_uuid))
          expect(assigns(:creation_form).parent_uuid).to eq(parent_uuid)
          expect(assigns(:creation_form).user_uuid).to eq(user_uuid)
          expect(assigns(:creation_form).purpose_uuid).to eq(child_purpose_uuid)
        end
      end
    end

    describe '#create' do
      setup do
        expect_any_instance_of(LabwareCreators::PoolTubesBySubmission).to receive(:save!).and_return(true)
        expect_any_instance_of(LabwareCreators::PoolTubesBySubmission).to receive(:child).and_return(build(:tube, uuid: child_uuid))
      end

      context 'from a tube parent' do
        it 'creates a tube' do
          post :create, params: { limber_plate_id: parent_uuid, tube: { purpose_uuid: child_purpose_uuid } }, session: { user_uuid: user_uuid }
          expect(response).to redirect_to(limber_tube_path(child_uuid))
          expect(assigns(:creation_form).parent_uuid).to eq(parent_uuid)
          expect(assigns(:creation_form).user_uuid).to eq(user_uuid)
          expect(assigns(:creation_form).purpose_uuid).to eq(child_purpose_uuid)
        end
      end

      context 'from a plate parent' do
        it 'creates a tube' do
          post :create, params: { limber_tube_id: parent_uuid, tube: { purpose_uuid: child_purpose_uuid } }, session: { user_uuid: user_uuid }
          expect(response).to redirect_to(limber_tube_path(child_uuid))
          expect(assigns(:creation_form).parent_uuid).to eq(parent_uuid)
          expect(assigns(:creation_form).user_uuid).to eq(user_uuid)
          expect(assigns(:creation_form).purpose_uuid).to eq(child_purpose_uuid)
        end
      end
    end
  end
end
