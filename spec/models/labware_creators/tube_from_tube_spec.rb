# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::TubeFromTube do
  has_a_working_api

  context 'pre creation' do
    describe '#creatable_from?' do
      subject { described_class.creatable_from?(parent) }

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

    let(:child_purpose_uuid) { SecureRandom.uuid }
    let(:parent_uuid) { SecureRandom.uuid }
    let(:user_uuid) { SecureRandom.uuid }
    let(:transfer_template_uuid) { 'transfer-between-specific-tubes' } # Defined in spec_helper.rb
    let(:child_tube) { create(:tube) }

    let(:transfers_attributes) do
      [
        {
          arguments: {
            user_uuid: user_uuid,
            source_uuid: parent_uuid,
            destination_uuid: child_tube.uuid,
            transfer_template_uuid: transfer_template_uuid
          }
        }
      ]
    end

    let(:tube_from_tubes_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

    describe '#save!' do
      it 'creates the child' do
        expect_transfer_creation
        expect_tube_from_tube_creation

        subject.save!
        expect(subject.redirection_target.uuid).to eq(child_tube.uuid)
      end
    end
  end
end
