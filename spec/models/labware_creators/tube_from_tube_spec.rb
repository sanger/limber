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
    subject do
      described_class.new(api, form_attributes)
    end

    it_behaves_like 'it has no custom page'

    before do
      Settings.transfer_templates['Transfer between specific tubes'] = transfer_template_uuid
      stub_api_get(transfer_template_uuid, body: json(:transfer_template, uuid: transfer_template_uuid))
      creation_request
      transfer_request
    end

    let(:controller) { TubeCreationController.new }
    let(:child_purpose_uuid) { 'child-purpose-uuid' }
    let(:parent_uuid) { 'parent-uuid' }
    let(:child_uuid) { 'child-uuid' }
    let(:user_uuid) { 'user-uuid' }
    let(:transfer_template_uuid) { 'transfer-between-specific-tubes' }

    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid:  parent_uuid,
        user_uuid: user_uuid
      }
    end

    let(:creation_request) do
      stub_api_post('tube_from_tube_creations',
                    payload: { tube_from_tube_creation: {
                      parent: 'parent-uuid',
                      child_purpose: 'child-purpose-uuid',
                      user: 'user-uuid'
                    } },
                    body: json(:tube_creation, child_uuid: child_uuid))
    end

    let(:transfer_request) do
      stub_api_post(transfer_template_uuid,
                    payload: { transfer: { user: user_uuid, source: parent_uuid, destination: child_uuid } },
                    body: json(:transfer_between_specific_tubes, destination_uuid: child_uuid))
    end

    describe '#save!' do
      it 'creates the child' do
        subject.save!
        expect(subject.child.uuid).to eq(child_uuid)
        expect(creation_request).to have_been_made.once
        expect(transfer_request).to have_been_made.once
      end
    end
  end
end
