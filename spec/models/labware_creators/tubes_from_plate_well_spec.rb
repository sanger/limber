# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::TubesFromPlateWell do
  has_a_working_api

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }
  let(:tubes_from_plate_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }

  context 'for pre creation' do
    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a plate' do
        let(:parent) { build :plate }

        it { is_expected.to be true }
      end
    end
  end

  context 'for creation' do
    subject { described_class.new(api, form_attributes) }

    let(:controller) { TubeCreationController.new }
    let(:child_purpose_uuid) { SecureRandom.uuid }
    let(:parent_uuid) { SecureRandom.uuid }
    let(:user_uuid) { SecureRandom.uuid }
    let(:child_tubes) { create_list(:tube, 2) }

    let(:transfer_attributes) do
      [{ arguments: { user_uuid: user_uuid, source_uuid: parent_uuid, destination_uuid: child_tube.uuid } }]
    end

    it_behaves_like 'it has no custom page'
  end
end
