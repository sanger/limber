# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/final_tube'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::TubeFromTube do
  has_a_working_api

  context 'pre creation' do
    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a tube' do
        let(:parent) { build :tube }
        it { is_expected.to be true }
      end

      context 'with a plate' do
        let(:parent) { build :plate }
        it { is_expected.to be false }
      end
    end
  end

  it_behaves_like 'it only allows creation from tubes'

  context 'on creation' do
    subject { described_class.new(api, form_attributes) }

    it_behaves_like 'it has no custom page'

    before do
      Settings.transfer_templates['Transfer between specific tubes'] = transfer_template_uuid
      creation_request
    end

    let(:controller) { TubeCreationController.new }
    let(:child_purpose_uuid) { 'child-purpose-uuid' }
    let(:parent_uuid) { 'parent-uuid' }
    let(:child_uuid) { 'child-uuid' }
    let(:user_uuid) { 'user-uuid' }
    let(:transfer_template_uuid) { 'transfer-between-specific-tubes' }

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

    let(:creation_request) do
      stub_api_post(
        'tube_from_tube_creations',
        payload: {
          tube_from_tube_creation: {
            parent: 'parent-uuid',
            child_purpose: 'child-purpose-uuid',
            user: 'user-uuid'
          }
        },
        body: json(:tube_creation, child_uuid: child_uuid)
      )
    end

    describe '#save!' do
      it 'creates the child' do
        expect_api_v2_posts(
          'Transfer',
          [
            {
              user_uuid: user_uuid,
              source_uuid: parent_uuid,
              destination_uuid: child_uuid,
              transfer_template_uuid: transfer_template_uuid
            }
          ]
        )

        subject.save!
        expect(subject.redirection_target.uuid).to eq(child_uuid)
        expect(creation_request).to have_been_made.once
      end
    end
  end
end
