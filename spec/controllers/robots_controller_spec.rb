# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/robots_controller'

RSpec.describe RobotsController, type: :controller, robots: true do
  include FeatureHelpers
  include RobotHelpers

  let(:settings) { YAML.load_file(Rails.root.join('spec/data/settings.yml')).with_indifferent_access }

  describe '#start' do
    has_a_working_api

    let(:user) { create :user }
    let(:plate) { create :v2_plate, purpose_name: 'target_plate_purpose', purpose_uuid: 'target_plate_purpose_uuid' }

    let!(:state_chage) do
      stub_api_post(
        'state_changes',
        payload: {
          state_change: {
            'target_state' => 'passed',
            'reason' => 'Robot robot_name started',
            'customer_accepts_responsibility' => false,
            'target' => plate.uuid,
            'user' => user.uuid,
            'contents' => nil
          }
        },
        body: json(:state_change)
      )
    end

    let(:metadata_payload) do
      { user_id: user.id, asset_id: plate.id, metadata: { created_with_robot: 'robot_barcode' } }
    end

    setup do
      Settings.robots['robot_id'] = settings[:robots][:robot_id]
      create :purpose_config,
             uuid: 'target_plate_purpose_uuid',
             state_changer_class: 'StateChangers::DefaultStateChanger'
      stub_v2_user(user)
      stub_v2_plate(plate)
      bed_labware_lookup(plate)

      # Legacy asset search
      stub_asset_search(
        plate.barcode.machine,
        json(:plate, uuid: plate.uuid, purpose_name: plate.purpose.name, purpose_uuid: plate.purpose.uuid)
      )
    end

    it 'adds robot barcode to plate metadata' do
      expect_api_v2_posts('CustomMetadatumCollection', [metadata_payload])

      post :start,
           params: {
             bed_labwares: {
               'bed1_barcode' => ['source_plate_barcode'],
               'bed2_barcode' => [plate.human_barcode]
             },
             robot_barcode: 'robot_barcode',
             id: 'robot_id'
           },
           session: {
             user_uuid: user.uuid
           }

      expect(flash[:notice]).to match 'Robot robot_name has been started.'
    end
  end

  describe '#verify' do
    has_a_working_api

    let(:user) { create :user }
    let(:target_plate) do
      create :v2_plate,
             purpose_name: 'target_plate_purpose',
             purpose_uuid: 'target_plate_purpose_uuid',
             parents: [source_plate]
    end
    let(:source_plate) do
      create :v2_plate, purpose_name: 'source_plate_purpose', purpose_uuid: 'source_plate_purpose_uuid'
    end

    it 'verifies robot and beds' do
      Settings.robots['robot_id'] = settings[:robots][:robot_id]
      bed_labware_lookup(source_plate)
      bed_labware_lookup(target_plate)
      expect_any_instance_of(Robots::Robot).to receive(:verify).with(
        'bed_labwares' => {
          'bed1_barcode' => [source_plate.human_barcode],
          'bed2_barcode' => [target_plate.human_barcode]
        },
        'robot_barcode' => 'abc'
      )
      post :verify,
           params: {
             bed_labwares: {
               'bed1_barcode' => [source_plate.human_barcode],
               'bed2_barcode' => [target_plate.human_barcode]
             },
             robot_barcode: 'abc',
             id: 'robot_id'
           },
           session: {
             user_uuid: user.uuid
           },
           format: :json
    end
  end
end
