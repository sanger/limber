# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::PoolingRobot do
  include FeatureHelpers

  has_a_working_api

  let(:settings)                    { YAML.load_file(Rails.root.join('spec', 'data', 'settings.yml')).with_indifferent_access }
  let(:user_uuid)                   { SecureRandom.uuid }
  let(:plate_uuid)                  { 'source-plate-uuid' }
  let(:source_barcode)              { ean13(1) }
  let(:source_purpose_name)         { 'Parent Purpose' }
  let(:source_purpose_uuid)         { SecureRandom.uuid }
  let(:source_plate_attributes) do
    {
      uuid: plate_uuid,
      barcode_number: 1,
      purpose_name: source_purpose_name,
      purpose_uuid: source_purpose_uuid,
      state: 'passed'
    }
  end

  let(:source_plate) { json :plate, source_plate_attributes }
  let(:target_barcode)              { ean13(2) }
  let(:target_purpose_name)         { 'Child Purpose' }
  let(:target_purpose_uuid)         { SecureRandom.uuid }
  let(:target_plate_uuid)           { 'target-plate-uuid' }
  let(:target_plate_attributes) do
    {
      uuid: target_plate_uuid,
      purpose_name: target_purpose_name,
      purpose_uuid: target_purpose_uuid,
      barcode_number: 2
    }
  end
  let(:target_plate)                { json :plate, target_plate_attributes }
  let(:metadata_uuid)               { SecureRandom.uuid }
  let(:custom_metadatum_collection) { json :custom_metdatum_collection, uuid: metadata_uuid }

  let(:robot) { Robots::PoolingRobot.new(robot_spec.merge(api: api, user_uuid: user_uuid)) }
  let(:robot_spec) { settings.dig(:robots, robot_id) }
  let(:robot_id) { 'pooling_robot_id' }

  let(:transfer_source_plates) { [associated(:plate, source_plate_attributes)] }

  before do
    create :purpose_config, uuid: source_purpose_uuid, name: source_purpose_name
    create :purpose_config, uuid: target_purpose_uuid, name: target_purpose_name

    stub_api_get(target_plate_uuid, 'creation_transfers',
                 body: json(:creation_transfer_collection,
                            destination: associated(:plate, target_plate_attributes),
                            sources: transfer_source_plates,
                            associated_on: 'creation_transfers',
                            transfer_factory: :creation_transfer))

    stub_asset_search(source_barcode, source_plate)
    stub_asset_search(target_barcode, target_plate)
  end

  describe '#verify' do
    subject { robot.verify(scanned_layout) }

    context 'a simple robot' do
      context 'with an unknown plate' do
        before(:each) { stub_asset_search('dodgy_barcode', nil) }
        let(:scanned_layout) { { settings[:robots][robot_id][:beds].keys.first => ['dodgy_barcode'] } }

        it { is_expected.not_to be_valid }
      end

      context 'with a plate on an unknown bed' do
        let(:scanned_layout) { { 'bed3_barcode' => [source_barcode] } }

        it { is_expected.not_to be_valid }
      end

      context 'with a valid layout' do
        let(:scanned_layout) { { 'bed1_barcode' => [source_barcode], 'bed5_barcode' => [target_barcode] } }

        context 'and related plates' do
          it { is_expected.to be_valid }
        end

        context 'but unrelated plates' do
          let(:transfer_source_plates) { [associated(:plate)] }
          it { is_expected.not_to be_valid }
        end
      end
    end

    context 'with multiple parents' do
      let(:source_plate2_attributes) do
        {
          uuid: plate_uuid,
          barcode_number: 3,
          purpose_name: source_purpose_name,
          purpose_uuid: source_purpose_uuid,
          state: 'passed'
        }
      end
      let(:source_barcode2) { ean13(3) }
      let(:source_plate2) { json :plate, source_plate2_attributes }
      let(:transfer_source_plates) { [associated(:plate, source_plate_attributes), associated(:plate, source_plate2_attributes)] }

      before do
        stub_asset_search(source_barcode2, source_plate2)
      end

      context 'with a valid layout' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_barcode],
            'bed2_barcode' => [source_barcode2],
            'bed5_barcode' => [target_barcode]
          }
        end

        context 'and related plates' do
          it { is_expected.to be_valid }
        end
      end

      context 'with source plates swapped' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_barcode2],
            'bed2_barcode' => [source_barcode],
            'bed5_barcode' => [target_barcode]
          }
        end

        context 'and related plates' do
          it { is_expected.not_to be_valid }
        end
      end
    end
  end

  describe '#perform_transfer' do
    let(:state_change_request) do
      stub_api_post('state_changes',
                    payload: {
                      state_change: {
                        target_state: 'passed',
                        reason: 'Robot Pooling Robot started',
                        customer_accepts_responsibility: false,
                        target: target_plate_uuid,
                        user: user_uuid,
                        contents: nil
                      }
                    },
                    body: json(:state_change, target_state: 'passed'))
    end

    before do
      state_change_request
    end

    it 'performs transfer from started to passed' do
      robot.perform_transfer('bed1_barcode' => [source_barcode], 'bed5_barcode' => [target_barcode])
      expect(state_change_request).to have_been_requested
    end
  end
end
