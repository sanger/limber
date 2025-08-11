# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlateCreationController do
  include FeatureHelpers

  # context 'for a plate with a custom-form' do
  #   # TODO: Add custom form tests if/when implemented
  # end

  let(:parent_uuid) { 'parent-uuid' }
  let(:child_purpose_uuid) { 'child-purpose-uuid' }
  let(:user_uuid) { 'user_uuid' }
  let(:child_uuid) { 'child_uuid' }

  context 'for a plate with an automatic form' do
    before { create :purpose_config, creator_class: 'LabwareCreators::StampedPlate', uuid: child_purpose_uuid }

    describe '#new' do
      it 'creates a plate from a plate parent' do
        get :new, params: { plate_id: parent_uuid, purpose_uuid: child_purpose_uuid }, session: { user_uuid: }
        expect(response).to render_template('new')
        expect(assigns(:labware_creator).parent_uuid).to eq(parent_uuid)
        expect(assigns(:labware_creator).user_uuid).to eq(user_uuid)
        expect(assigns(:labware_creator).purpose_uuid).to eq(child_purpose_uuid)
      end

      it 'creates a plate from a tube parent' do
        get :new, params: { tube_id: parent_uuid, purpose_uuid: child_purpose_uuid }, session: { user_uuid: }
        expect(response).to render_template('new')
        expect(assigns(:labware_creator).parent_uuid).to eq(parent_uuid)
        expect(assigns(:labware_creator).user_uuid).to eq(user_uuid)
        expect(assigns(:labware_creator).purpose_uuid).to eq(child_purpose_uuid)
      end
    end

    describe '#create' do
      let(:parent) { build(:plate, uuid: parent_uuid) }
      let(:child) { build(:plate, uuid: child_uuid) }

      before do
        allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(uuid: parent_uuid).and_return(parent)
        allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(uuid: child_uuid).and_return(child)
        allow(Sequencescape::Api::V2::PlateCreation).to receive(:create!).and_return(
          instance_double(Sequencescape::Api::V2::PlateCreation, child:)
        )
        allow(Sequencescape::Api::V2::TransferRequestCollection).to receive(:create!)
      end

      context 'from a plate parent' do
        it 'creates a plate' do
          post :create,
               params: {
                 plate_id: parent_uuid,
                 plate: {
                   purpose_uuid: child_purpose_uuid
                 }
               },
               session: {
                 user_uuid:
               }
          expect(response).to redirect_to("#{plate_path(child_uuid)}#summary_tab")
          expect(assigns(:labware_creator).parent_uuid).to eq(parent_uuid)
          expect(assigns(:labware_creator).user_uuid).to eq(user_uuid)
          expect(assigns(:labware_creator).purpose_uuid).to eq(child_purpose_uuid)
        end
      end

      context 'from a tube parent' do
        it 'creates a plate' do
          post :create,
               params: {
                 tube_id: parent_uuid,
                 plate: {
                   purpose_uuid: child_purpose_uuid
                 }
               },
               session: {
                 user_uuid:
               }
          expect(response).to redirect_to("#{plate_path(child_uuid)}#summary_tab")
          expect(assigns(:labware_creator).parent_uuid).to eq(parent_uuid)
          expect(assigns(:labware_creator).user_uuid).to eq(user_uuid)
          expect(assigns(:labware_creator).purpose_uuid).to eq(child_purpose_uuid)
        end
      end
    end
  end
end
