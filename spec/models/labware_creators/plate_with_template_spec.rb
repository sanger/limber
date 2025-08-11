# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::PlateWithTemplate do
  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  let(:child_uuid) { 'child-uuid' }
  let(:child_plate) { create :plate, uuid: child_uuid, purpose_uuid: child_purpose_uuid }
  let(:parent_uuid) { 'example-plate-uuid' }
  let(:transfer_template_uuid) { 'custom-transfer-template' } # Defined in spec_helper.rb

  let(:transfers_attributes) do
    [
      {
        arguments: {
          user_uuid: user_uuid,
          source_uuid: parent_uuid,
          destination_uuid: child_uuid,
          transfer_template_uuid: transfer_template_uuid
        }
      }
    ]
  end

  let(:child_purpose_uuid) { 'child-purpose' }

  let(:user_uuid) { 'user-uuid' }

  before { create(:templated_transfer_config, uuid: child_purpose_uuid) }

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a described_class
    end
  end

  describe '#save!' do
    let(:plate_creations_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }

    it 'makes the expected requests' do
      expect_plate_creation
      expect_transfer_creation

      expect(subject.save!).to be true
    end
  end
end
