# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::PoolingRobot, :robots do
  include RobotHelpers

  let(:source_plate_attributes) do
    {
      uuid: plate_uuid,
      barcode_number: 1,
      purpose_name: source_purpose_name,
      purpose_uuid: source_purpose_uuid,
      state: 'passed'
    }
  end

  let(:target_plate_attributes) do
    {
      uuid: target_plate_uuid,
      purpose_name: target_purpose_name,
      purpose_uuid: target_purpose_uuid,
      barcode_number: 2,
      parents: target_plate_parents,
      wells: wells,
      state: target_plate_state
    }
  end

  let(:user_uuid) { SecureRandom.uuid }
  let(:plate_uuid) { SecureRandom.uuid }
  let(:target_plate_uuid) { SecureRandom.uuid }
  let(:source_barcode) { source_plate.human_barcode }
  let(:source_purpose_name) { 'Parent Purpose' }
  let(:source_purpose_uuid) { SecureRandom.uuid }
  let(:target_plate_state) { 'pending' }
  let(:source_plate) { create :v2_plate, source_plate_attributes }
  let(:target_barcode) { target_plate.human_barcode }
  let(:target_purpose_name) { 'Child Purpose' }
  let(:target_purpose_uuid) { SecureRandom.uuid }
  let(:target_plate) { create :v2_plate, target_plate_attributes }

  let(:target_plate_parents) { [source_plate] }

  let(:robot) { described_class.new(robot_spec.merge(user_uuid:)) }

  let(:robot_spec) do
    {
      'name' => 'Pooling Robot',
      'layout' => 'bed',
      'beds' => {
        'bed1_barcode' => {
          'purpose' => 'Parent Purpose',
          'states' => %w[passed qc_complete],
          'child' => 'bed5_barcode',
          'label' => 'Bed 2'
        },
        'bed2_barcode' => {
          'purpose' => 'Parent Purpose',
          'states' => %w[passed qc_complete],
          'child' => 'bed5_barcode',
          'label' => 'Bed 5'
        },
        'bed3_barcode' => {
          'purpose' => 'Parent Purpose',
          'states' => %w[passed qc_complete],
          'child' => 'bed5_barcode',
          'label' => 'Bed 3'
        },
        'bed4_barcode' => {
          'purpose' => 'Parent Purpose',
          'states' => %w[passed qc_complete],
          'child' => 'bed5_barcode',
          'label' => 'Bed 6'
        },
        'bed5_barcode' => {
          'purpose' => 'Child Purpose',
          'states' => %w[pending started],
          'parents' => %w[
            bed1_barcode
            bed2_barcode
            bed3_barcode
            bed4_barcode
            bed1_barcode
            bed2_barcode
            bed3_barcode
            bed4_barcode
          ],
          'target_state' => 'passed',
          'label' => 'Bed 4'
        }
      },
      'destination_bed' => 'bed5_barcode',
      'class' => 'Robots::PoolingRobot'
    }
  end

  let(:transfer_source_plates) { [source_plate] }

  let(:wells) do
    %w[C1 D1].map { |location| create :v2_well, location: location, upstream_plates: transfer_source_plates }
  end

  before do
    create :purpose_config, uuid: source_purpose_uuid, name: source_purpose_name
    create :purpose_config, uuid: target_purpose_uuid, name: target_purpose_name

    bed_plate_lookup(source_plate, [:purpose, { wells: :upstream_plates }])
    bed_plate_lookup(target_plate, [:purpose, { wells: :upstream_plates }])
  end

  describe '#verify' do
    subject { robot.verify(bed_labwares: scanned_layout) }

    context 'a simple robot' do
      context 'with an unknown plate' do
        before { bed_plate_lookup_with_barcode('dodgy_barcode', [], [:purpose, { wells: :upstream_plates }]) }

        let(:scanned_layout) { { 'bed1_barcode' => ['dodgy_barcode'] } }

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
          let(:transfer_source_plates) { [create(:v2_plate)] }

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
      let(:source_barcode2) { source_plate2.human_barcode }
      let(:source_plate2) { create :v2_plate, source_plate2_attributes }
      let(:transfer_source_plates) { [source_plate, source_plate2] }

      let(:wells) do
        %w[C1 D1].map { |location| create :v2_well, location: location, upstream_plates: [transfer_source_plates[1]] } +
          %w[A1 B1].map { |location| create :v2_well, location: location, upstream_plates: [transfer_source_plates[0]] }
      end

      before { bed_plate_lookup(source_plate2, [:purpose, { wells: :upstream_plates }]) }

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
    let(:state_changes_attributes) do
      [
        {
          contents: nil,
          customer_accepts_responsibility: false,
          reason: 'Robot Pooling Robot started',
          target_state: 'passed',
          target_uuid: target_plate_uuid,
          user_uuid: user_uuid
        }
      ]
    end

    it 'performs transfer from started to passed' do
      expect_state_change_creation

      robot.perform_transfer('bed1_barcode' => [source_barcode], 'bed5_barcode' => [target_barcode])
    end

    context 'if the bed is unexpectedly invalid' do
      let(:target_plate_state) { 'passed' }

      it 'raises a bed error in the event of last-minute errors' do
        expect do
          robot.perform_transfer('bed1_barcode' => [source_barcode], 'bed5_barcode' => [target_barcode])
        end.to raise_error(Robots::Bed::BedError)
      end
    end
  end
end
