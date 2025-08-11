# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::SplittingRobot, :robots do
  include FeatureHelpers
  include RobotHelpers

  let(:user_uuid) { SecureRandom.uuid }

  let(:wells) { %w[C1 D1].map { |location| create :well, location: location, downstream_plates: transfer_target_1 } }
  let(:transfer_target_1) { [target_plate_1] }

  let(:source_barcode) { source_plate.human_barcode }
  let(:source_purpose_name) { 'Limber Cherrypicked' }
  let(:source_plate_state) { 'passed' }
  let(:source_plate) do
    create :plate, barcode_number: 1, purpose_name: source_purpose_name, state: source_plate_state, wells: wells
  end
  let(:target_barcode_1) { target_plate_1.human_barcode }
  let(:target_barcode_2) { target_plate_2.human_barcode }
  let(:target_purpose_name) { 'target_plate_purpose' }
  let(:target_plate_1) { create :plate, purpose_name: target_purpose_name, barcode_number: 2 }
  let(:target_plate_2) { create :plate, purpose_name: target_purpose_name, barcode_number: 3 }

  let(:robot) { described_class.new(robot_spec.merge(user_uuid:)) }

  describe '#verify' do
    subject { robot.verify(bed_labwares: scanned_layout) }

    context 'a simple robot' do
      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'class' => 'Robots::SplittingRobot',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => 'Limber Cherrypicked',
              'states' => ['passed'],
              'label' => 'Bed 2'
            },
            'bed2_barcode' => {
              'purpose' => 'target_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 2',
              'parent' => 'bed1_barcode',
              'target_state' => 'passed'
            },
            'bed3_barcode' => {
              'purpose' => 'target_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 3',
              'parent' => 'bed1_barcode',
              'target_state' => 'passed'
            }
          },
          'relationships' => [
            {
              'type' => 'quad_stamp_out',
              'options' => {
                'parent' => 'bed1_barcode',
                'children' => %w[bed2_barcode bed3_barcode]
              }
            }
          ]
        }
      end

      before do
        bed_plate_lookup(source_plate, [:purpose, { wells: :downstream_plates }])
        bed_plate_lookup(target_plate_1, [:purpose, { wells: :downstream_plates }])
        bed_plate_lookup(target_plate_2, [:purpose, { wells: :downstream_plates }])
      end

      context 'with an unknown plate' do
        before { bed_plate_lookup_with_barcode('dodgy_barcode', [], [:purpose, { wells: :downstream_plates }]) }

        let(:scanned_layout) { { 'bed1_barcode' => ['dodgy_barcode'] } }

        it { is_expected.not_to be_valid }
      end

      context 'with a plate on an unknown bed' do
        let(:scanned_layout) { { 'bed12_barcode' => [source_barcode] } }

        it { is_expected.not_to be_valid }
      end

      context 'with a valid layout' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_barcode],
            'bed2_barcode' => [target_barcode_1],
            'bed3_barcode' => [target_barcode_2]
          }
        end

        context 'and related plates' do
          it { is_expected.to be_valid }
        end

        context 'but unrelated plates' do
          let(:transfer_target_1) { [create(:plate)] }

          it { is_expected.not_to be_valid }
        end
      end

      context 'with plates in the wrong order' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_barcode],
            'bed2_barcode' => [target_barcode_2],
            'bed3_barcode' => [target_barcode_1]
          }
        end

        context 'and related plates' do
          it { is_expected.not_to be_valid }
        end
      end
    end
  end

  describe '#perform_transfer' do
    let(:robot_spec) do
      {
        'name' => 'bravo LB End Prep',
        'layout' => 'bed',
        'verify_robot' => true,
        'beds' => {
          '580000014851' => {
            'purpose' => 'LB End Prep',
            'states' => ['started'],
            'label' => 'Bed 14',
            'target_state' => 'passed'
          }
        }
      }
    end

    let(:plate) do
      create :plate,
             barcode_number: '123',
             purpose_uuid: 'lb_end_prep_uuid',
             purpose_name: 'LB End Prep',
             state: 'started'
    end

    let(:state_changes_attributes) do
      [
        {
          contents: nil,
          customer_accepts_responsibility: false,
          reason: 'Robot bravo LB End Prep started',
          target_state: 'passed',
          target_uuid: plate.uuid,
          user_uuid: user_uuid
        }
      ]
    end

    before do
      create :purpose_config, uuid: 'lb_end_prep_uuid', state_changer_class: 'StateChangers::PlateStateChanger'
      bed_plate_lookup(plate, [:purpose, { wells: :downstream_plates }])
    end

    it 'performs transfer from started to passed' do
      expect_state_change_creation

      robot.perform_transfer('580000014851' => [plate.human_barcode])
    end
  end
end
