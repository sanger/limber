# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::Robot do
  include FeatureHelpers

  has_a_working_api

  let(:settings)                    { YAML.load_file(Rails.root.join('spec', 'data', 'settings.yml')).with_indifferent_access }
  let(:user_uuid)                   { SecureRandom.uuid }
  let(:plate_uuid)                  { SecureRandom.uuid }
  let(:source_barcode)              { ean13(1) }
  let(:source_purpose_name)         { 'Limber Cherrypicked' }
  let(:source_purpose_uuid)         { SecureRandom.uuid }
  let(:plate)                       do
    json :plate,
         uuid: plate_uuid,
         barcode_number: 1,
         purpose_name: source_purpose_name,
         purpose_uuid: source_purpose_uuid,
         state: 'passed'
  end
  let(:target_barcode)              { ean13(2) }
  let(:target_purpose_name)         { 'target_plate_purpose' }
  let(:target_purpose_uuid)         { SecureRandom.uuid }
  let(:target_plate)                { json :plate, purpose_name: target_purpose_name, purpose_uuid: target_purpose_uuid, barcode_number: 2 }
  let(:metadata_uuid)               { SecureRandom.uuid }
  let(:custom_metadatum_collection) { json :custom_metdatum_collection, uuid: metadata_uuid }

  let(:robot) { Robots::Robot.new(robot_spec.merge(api: api, user_uuid: user_uuid)) }
  let(:robot_spec) { settings[:robots][robot_id] }

  describe '#verify' do
    subject { robot.verify(scanned_layout) }

    context 'a simple robot' do
      let(:robot_id) { 'robot_id' }

      before do
        Settings.purpose_uuids[source_purpose_name] = source_purpose_uuid
        Settings.purpose_uuids[target_purpose_name] = target_purpose_uuid

        stub_asset_search(source_barcode, plate)
        stub_asset_search(target_barcode, target_plate)
      end

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
        let(:scanned_layout) { { 'bed1_barcode' => [source_barcode], 'bed2_barcode' => [target_barcode] } }

        context 'and related plates' do
          before(:each) do
            stub_search_and_single_result('Find source assets by destination asset barcode', { 'search' => { 'barcode' => target_barcode } }, plate)
          end
          it { is_expected.to be_valid }
        end

        context 'but unrelated plates' do
          before(:each) do
            stub_search_and_single_result('Find source assets by destination asset barcode', { 'search' => { 'barcode' => target_barcode } }, json(:plate))
          end
          it { is_expected.not_to be_valid }
        end
      end
    end

    context 'a robot with grandchildren' do
      let(:robot_id) { 'grandparent_robot' }
      let(:grandchild_purpose_name) { 'target2_plate_purpose' }
      let(:grandchild_purpose_uuid) { SecureRandom.uuid }
      let(:grandchild_barcode)      { ean13(3) }
      let(:grandchild_plate) do
        json :plate,
             uuid: plate_uuid,
             purpose_name: grandchild_purpose_name,
             purpose_uuid: grandchild_purpose_uuid,
             barcode_number: 3
      end

      before(:each) do
        Settings.purpose_uuids[source_purpose_name] = source_purpose_uuid
        Settings.purpose_uuids[target_purpose_name] = target_purpose_uuid
        stub_asset_search(source_barcode, plate)
        stub_asset_search(target_barcode, target_plate)
        Settings.purpose_uuids[grandchild_purpose_name] = grandchild_purpose_uuid
        stub_asset_search(grandchild_barcode, grandchild_plate)
        stub_search_and_single_result('Find source assets by destination asset barcode', { 'search' => { 'barcode' => target_barcode } }, plate)
        stub_search_and_single_result('Find source assets by destination asset barcode', { 'search' => { 'barcode' => grandchild_barcode } }, target_plate)
      end

      context 'and the correct layout' do
        let(:scanned_layout) { { 'bed1_barcode' => [source_barcode], 'bed2_barcode' => [target_barcode], 'bed3_barcode' => [grandchild_barcode] } }
        it { is_expected.to be_valid }
      end
    end

    describe 'robot barcode' do
      let(:robot_id) { 'robot_id_2' }

      before do
        Settings.purpose_uuids['Limber Cherrypicked'] = 'limber_cherrypicked_uuid'
        stub_asset_search('123', plate_json)
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
    let(:robot_id) { 'bravo-lb-end-prep' }

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
      Settings.purpose_uuids['LB End Prep'] = 'lb_end_prep_uuid'
      Settings.purposes['lb_end_prep_uuid'] = { state_changer_class: 'StateChangers::DefaultStateChanger' }
      state_change_request
      stub_asset_search('123', plate_json)
    end

    it 'performs transfer from started to passed' do
      robot.perform_transfer(robot.beds.keys.first => ['123'])
      expect(state_change_request).to have_been_requested
    end
  end
end
