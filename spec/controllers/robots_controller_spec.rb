# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/robots_controller'

describe RobotsController, type: :controller do
  include FeatureHelpers

  let(:settings) { YAML.load_file(Rails.root.join('spec', 'data', 'settings.yml')).with_indifferent_access }

  describe '#start' do
    has_a_working_api

    let(:user_uuid) { SecureRandom.uuid }
    let(:plate_uuid) { 'plate_uuid' }
    let!(:plate)     { json :plate, uuid: plate_uuid, purpose_name: 'target_plate_purpose', purpose_uuid: 'target_plate_purpose_uuid' }

    let!(:state_chage) do
      stub_api_post(
        'state_changes',
        payload: {
          state_change: {
            'target_state' => 'passed',
            'reason' => 'Robot robot_name started',
            'customer_accepts_responsibility' => false,
            'target' => 'plate_uuid',
            'user' => user_uuid,
            'contents' => nil
          }
        },
        body: json(:state_change)
      )
    end

    let!(:metadata_request) do
      stub_api_post('custom_metadatum_collections',
                    payload: { custom_metadatum_collection: { user: user_uuid, asset: plate_uuid, metadata: { created_with_robot: 'robot_barcode' } } },
                    body: json(:custom_metadatum_collection))
    end

    setup do
      Settings.robots['robot_id'] = settings[:robots][:robot_id]
      Settings.purpose_uuids['target_plate_purpose'] = 'target_plate_purpose_uuid'
      Settings.purposes['target_plate_purpose_uuid'] = { state_changer_class: 'StateChangers::DefaultStateChanger' }
      stub_asset_search('target_plate_barcode', plate)
    end

    it 'adds robot barcode to plate metadata' do
      post :start,
           params: {
             bed: {
               'bed1_barcode' => ['source_plate_barcode'],
               'bed2_barcode' => ['target_plate_barcode']
             },
             robot_barcode: 'robot_barcode',
             id: 'robot_id'
           },
           session: { user_uuid: user_uuid }
      expect(metadata_request).to have_been_requested
      expect(flash[:notice]).to match 'Robot robot_name has been started.'
    end
  end

  describe '#verify' do
    has_a_working_api

    let(:user_uuid) { SecureRandom.uuid }
    let(:target_plate_uuid) { 'plate_uuid' }
    let!(:target_plate)     { json :plate, uuid: target_plate_uuid, purpose_name: 'target_plate_purpose', purpose_uuid: 'target_plate_purpose_uuid' }

    let(:source_plate_uuid) { 'plate_uuid' }
    let!(:source_plate)     { json :plate, uuid: source_plate_uuid, purpose_name: 'source_plate_purpose', purpose_uuid: 'source_plate_purpose_uuid' }

    it 'verifies robot and beds' do
      source_plate_barcode = JSON.parse(source_plate)['plate']['barcode']['ean13']
      target_plate_barcode = JSON.parse(target_plate)['plate']['barcode']['ean13']
      Settings.robots['robot_id'] = settings[:robots][:robot_id]
      stub_asset_search(source_plate_barcode, source_plate)
      stub_asset_search(target_plate_barcode, target_plate)
      stub_search_and_single_result('Find source assets by destination asset barcode', { 'search' => { 'barcode' => target_plate_barcode } }, source_plate)
      expect_any_instance_of(Robots::Robot).to receive(:verify).with({ 'bed1_barcode' => [source_plate_barcode], 'bed2_barcode' => [target_plate_barcode] }, 'abc')
      post :verify,
           params: {
             beds: {
               'bed1_barcode' => [source_plate_barcode],
               'bed2_barcode' => [target_plate_barcode]
             },
             robot_barcode: 'abc',
             id: 'robot_id'
           },
           session: { user_uuid: user_uuid },
           format: :json
    end
  end
end
