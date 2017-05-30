# frozen_string_literal: true

require 'rails_helper'

describe Robots::Robot do
  include FeatureHelpers

  let(:api)                         { Sequencescape::Api.new(Limber::Application.config.api_connection_options) }
  let(:settings)                    { YAML.load_file(Rails.root.join('spec', 'data', 'settings.yml')).with_indifferent_access }
  let(:user_uuid)                   { SecureRandom.uuid }
  let(:plate_uuid)                  { SecureRandom.uuid }
  let(:plate)                       { json :stock_plate, uuid: plate_uuid }
  let(:metadata_uuid)               { SecureRandom.uuid }
  let(:custom_metadatum_collection) { json :custom_metdatum_collection, uuid: metadata_uuid }

  describe '#verify' do
    describe 'plate and bed' do
      let(:robot) { Robots::Robot.find(id: 'robot_id', api: api, user_uuid: user_uuid) }

      before do
        Settings.robots['robot_id'] = settings[:robots][:robot_id]
      end

      has_a_working_api

      it 'returns an error if there is an invalid bed' do
        stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 'dodgy_barcode' } }, nil)
        expect(robot.verify(settings[:robots][:robot_id][:beds].keys.first => ['dodgy_barcode'])[:valid]).to be_falsey
      end

      it 'returns an error if the plate is not on the right bed' do
        stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 'plate_barcode' } }, plate)
        expect(robot.verify(settings[:robots][:robot_id][:beds].keys.first => ['plate_barcode'])[:valid]).to be_falsey
      end
    end

    describe 'robot barcode' do
      has_a_working_api

      let(:robot) { Robots::Robot.find(id: 'robot_id_2', api: api, user_uuid: user_uuid) }

      before do
        Settings.purpose_uuids['Limber Cherrypicked'] = 'limber_cherrypicked_uuid'
        Settings.robots['robot_id_2'] = settings[:robots][:robot_id_2]
        stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => '123' } }, plate_json)
      end

      context 'without metadata' do
        let(:plate_json) do
          json :stock_plate,
               uuid: plate_uuid,
               barcode_number: '123',
               purpose_uuid: 'limber_cherrypicked_uuid',
               state: 'passed'
        end

        it 'is invalid' do
          expect(robot.verify(settings[:robots][:robot_id_2][:beds].keys.first => ['123'])[:valid]).to be_falsey
        end
      end

      context 'without plate' do
        let(:plate_json) { nil }

        it 'is invalid' do
          expect(robot.verify(settings[:robots][:robot_id_2][:beds].keys.first => ['123'])[:valid]).to be_falsey
        end
      end

      context 'with metadata' do
        let(:plate_json) do
          json :stock_plate_with_metadata,
               uuid: plate_uuid,
               barcode_number: '123',
               purpose_uuid: 'limber_cherrypicked_uuid',
               state: 'passed',
               custom_metadatum_collection_uuid: 'custom_metadatum_collection-uuid'
        end

        it "is invalid if the barcode isn't recorded" do
          stub_api_get('custom_metadatum_collection-uuid',
                       body: json(:custom_metadatum_collection, uuid: 'custom_metadatum_collection-uuid'))
          expect(robot.verify({ settings[:robots][:robot_id_2][:beds].keys.first => ['123'] }, 'robot_barcode')[:valid]).to be_falsey
        end

        it "is invalid if the barcode doesn't match" do
          stub_api_get('custom_metadatum_collection-uuid',
                       body: json(:custom_metadatum_collection,
                                  metadata: { 'created_with_robot' => 'other_robot' },
                                  uuid: 'custom_metadatum_collection-uuid'))
          expect(robot.verify({ settings[:robots][:robot_id_2][:beds].keys.first => ['123'] }, 'robot_barcode')[:valid]).to be_falsey
        end

        it 'is valid id the metadata matches' do
          stub_api_get('custom_metadatum_collection-uuid',
                       body: json(:custom_metadatum_collection,
                                  metadata: { 'created_with_robot' => 'robot_barcode' },
                                  uuid: 'custom_metadatum_collection-uuid'))
          expect(robot.verify({ settings[:robots][:robot_id_2][:beds].keys.first => ['123'] }, 'robot_barcode')[:valid]).to be_truthy
        end
      end
    end
  end

  describe '#perform_transfer' do
    has_a_working_api

    let(:robot) { Robots::Robot.find(id: 'bravo-lb-end-prep', api: api, user_uuid: user_uuid) }

    let(:state_change_request) do
      stub_api_post('state_changes',
                    payload: {
                      state_change: {
                        target_state: 'passed',
                        reason: 'Robot bravo LB End Prep started',
                        customer_accepts_responsibility: false,
                        target: plate_uuid,
                        user: user_uuid,
                        contents: nil
                      }
                    },
                    body: json(:state_change, target_state: 'passed'))
    end

    let(:plate_json) do
      json :stock_plate,
           uuid: plate_uuid,
           barcode_number: '123',
           purpose_uuid: 'lb_end_prep_uuid',
           purpose_name: 'LB End Prep',
           state: 'started'
    end

    before do
      Settings.robots['bravo-lb-end-prep'] = settings[:robots]['bravo-lb-end-prep']
      Settings.purpose_uuids['LB End Prep'] = 'lb_end_prep_uuid'
      Settings.purposes['lb_end_prep_uuid'] = { state_changer_class: 'StateChangers::DefaultStateChanger' }
      state_change_request
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => '123' } }, plate_json)
    end

    it 'performs transfer from started to passed' do
      robot.perform_transfer(robot.beds.keys.first => ['123'])
      expect(state_change_request).to have_been_requested
    end
  end
end
