# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::Bed::PlateToTubeRacksBed do
  # user
  subject { described_class.new }

  let(:user) { create :user }
  let(:user_uuid) { user.uuid }

  # robot barcode
  let(:robot_barcode) { 'robot_barcode' }

  # tube uuids
  let(:tube1_uuid) { 'tube1_uuid' }
  let(:tube2_uuid) { 'tube2_uuid' }

  # tube purpose uuid
  let(:tube_purpose_uuid) { 'tube_purpose_uuid' }

  # tube purpose name
  let(:tube_purpose_name) { 'tube_purpose_name' }

  # tube purpose
  let(:tube_purpose) { create(:v2_purpose, name: tube_purpose_name, uuid: tube_purpose_uuid) }

  # tube states
  let(:tube1_state) { 'pending' }
  let(:tube2_state) { 'pending' }

  # tubes
  let(:tube1) do
    create(
      :v2_tube,
      uuid: tube1_uuid,
      barcode_prefix: 'FX',
      barcode_number: 4,
      purpose: tube_purpose,
      state: tube1_state
    )
  end
  let(:tube2) do
    create(
      :v2_tube,
      uuid: tube2_uuid,
      barcode_prefix: 'FX',
      barcode_number: 5,
      purpose: tube_purpose,
      state: tube2_state
    )
  end

  # tube rack purpose uuid
  let(:tube_rack_purpose_uuid) { 'tube_rack_purpose_uuid' }

  # tube rack purpose name
  let(:tube_rack_purpose_name) { 'tube_rack_purpose_name' }

  # tube rack purpose
  let(:tube_rack_purpose) { create(:v2_tube_rack_purpose, name: tube_rack_purpose_name, uuid: tube_rack_purpose_uuid) }

  # tube rack uuid
  let(:tube_rack_uuid) { 'tube_rack_uuid' }

  # tube rack
  let!(:tube_rack) do
    create(
      :tube_rack,
      purpose: tube_rack_purpose,
      barcode_number: 1,
      barcode_prefix: 'TR',
      uuid: tube_rack_uuid,
      tubes: {
        A1: tube1,
        B1: tube2
      }
    )
  end

  let(:tube_rack_custom_metadatum_collections_attributes) do
    [{ user_id: user.id, asset_id: tube_rack.id, metadata: { created_with_robot: robot_barcode } }]
  end

  let(:tube1_custom_metadatum_collections_attributes) do
    [{ user_id: user.id, asset_id: tube1.id, metadata: { created_with_robot: robot_barcode } }]
  end

  let(:tube2_custom_metadatum_collections_attributes) do
    [{ user_id: user.id, asset_id: tube2.id, metadata: { created_with_robot: robot_barcode } }]
  end

  before do
    stub_v2_user(user)
    stub_v2_labware(tube_rack)
    stub_v2_tube(tube1)
    stub_v2_tube(tube2)

    allow(subject).to receive_messages(labware: tube_rack, user_uuid: user_uuid)
  end

  describe '#labware_created_with_robot' do
    it 'updates the tube rack and the tube labware metadata with the robot barcode' do
      expect_api_v2_posts('CustomMetadatumCollection', tube_rack_custom_metadatum_collections_attributes)
      expect_api_v2_posts('CustomMetadatumCollection', tube1_custom_metadatum_collections_attributes)
      expect_api_v2_posts('CustomMetadatumCollection', tube2_custom_metadatum_collections_attributes)

      subject.labware_created_with_robot(robot_barcode)
    end
  end
end
