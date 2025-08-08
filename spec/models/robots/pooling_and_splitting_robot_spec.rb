# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::PoolingAndSplittingRobot, :robots do
  include RobotHelpers

  has_a_working_api

  # robot has at least one source, and can have multiple
  let(:source_plate_1_attributes) do
    {
      uuid: source_plate_1_uuid,
      barcode_number: 1,
      purpose_name: source_purpose_name,
      purpose_uuid: source_purpose_uuid,
      state: source_plate_state
    }
  end

  # robot always has multiple destinations
  let(:target_plate_1_attributes) do
    {
      uuid: target_plate_1_uuid,
      purpose_name: target_1_purpose_name,
      purpose_uuid: target_1_purpose_uuid,
      barcode_number: 2,
      parents: target_plate_1_parents,
      wells: target_1_wells
    }
  end

  let(:target_plate_2_attributes) do
    {
      uuid: target_plate_2_uuid,
      purpose_name: target_2_purpose_name,
      purpose_uuid: target_2_purpose_uuid,
      barcode_number: 3,
      parents: target_plate_2_parents,
      wells: target_2_wells
    }
  end

  let(:user_uuid) { SecureRandom.uuid }

  let(:source_purpose_name) { 'Parent Purpose' }
  let(:source_purpose_uuid) { SecureRandom.uuid }
  let(:source_plate_state) { 'passed' }

  let(:source_plate_1_uuid) { SecureRandom.uuid }
  let(:source_1_barcode) { source_plate_1.human_barcode }
  let(:source_plate_1) { create :v2_plate, source_plate_1_attributes }

  let(:transfer_source_plates) { [source_plate_1] }

  let(:target_plate_1_uuid) { SecureRandom.uuid }
  let(:target_1_barcode) { target_plate_1.human_barcode }
  let(:target_1_purpose_name) { 'Child Purpose 1' }
  let(:target_1_purpose_uuid) { SecureRandom.uuid }
  let(:target_plate_1_parents) { [source_plate_1] }
  let(:target_1_wells) do
    %w[A1 B1 C1 D1].map { |location| create :v2_well, location: location, upstream_plates: transfer_source_plates }
  end
  let(:target_plate_1) { create :v2_plate, target_plate_1_attributes }

  let(:target_plate_2_uuid) { SecureRandom.uuid }
  let(:target_2_barcode) { target_plate_2.human_barcode }
  let(:target_2_purpose_name) { 'Child Purpose 2' }
  let(:target_2_purpose_uuid) { SecureRandom.uuid }
  let(:target_plate_2_parents) { [source_plate_1] }
  let(:target_2_wells) do
    %w[A1 B1 C1 D1].map { |location| create :v2_well, location: location, upstream_plates: transfer_source_plates }
  end
  let(:target_plate_2) { create :v2_plate, target_plate_2_attributes }

  let(:robot) { described_class.new(robot_spec.merge(api:, user_uuid:)) }

  let(:robot_spec) do
    {
      'name' => 'Pooling And Splitting Robot',
      'layout' => 'bed',
      'beds' => {
        'bed1_barcode' => {
          'purpose' => 'Parent Purpose',
          'states' => %w[passed qc_complete],
          'label' => 'Bed 1'
        },
        'bed2_barcode' => {
          'purpose' => 'Parent Purpose',
          'states' => %w[passed qc_complete],
          'label' => 'Bed 2'
        },
        'bed3_barcode' => {
          'purpose' => 'Parent Purpose',
          'states' => %w[passed qc_complete],
          'label' => 'Bed 3'
        },
        'bed4_barcode' => {
          'purpose' => 'Parent Purpose',
          'states' => %w[passed qc_complete],
          'label' => 'Bed 4'
        },
        'bed5_barcode' => {
          'purpose' => 'Child Purpose 1',
          'states' => %w[pending started],
          'target_state' => 'passed',
          'label' => 'Bed 5'
        },
        'bed6_barcode' => {
          'purpose' => 'Child Purpose 2',
          'states' => %w[pending started],
          'target_state' => 'passed',
          'label' => 'Bed 6'
        }
      },
      'class' => 'Robots::PoolingAndSplittingRobot',
      'relationships' => [
        {
          'type' => 'pool_and_split',
          'options' => {
            'parents' => %w[bed1_barcode bed2_barcode bed3_barcode bed4_barcode],
            'children' => %w[bed5_barcode bed6_barcode]
          }
        }
      ]
    }
  end

  before do
    create :purpose_config, uuid: source_purpose_uuid, name: source_purpose_name
    create :purpose_config, uuid: target_1_purpose_uuid, name: target_1_purpose_name
    create :purpose_config, uuid: target_2_purpose_uuid, name: target_2_purpose_name

    bed_plate_lookup(source_plate_1, [:purpose, { wells: :upstream_plates }])
    bed_plate_lookup(target_plate_1, [:purpose, { wells: :upstream_plates }])
    bed_plate_lookup(target_plate_2, [:purpose, { wells: :upstream_plates }])
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
        let(:scanned_layout) { { 'bed7_barcode' => [source_1_barcode] } }

        it { is_expected.not_to be_valid }
      end

      context 'with a valid layout' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_1_barcode],
            'bed5_barcode' => [target_1_barcode],
            'bed6_barcode' => [target_2_barcode]
          }
        end

        context 'and related plates' do
          it { is_expected.to be_valid }
        end

        context 'but unrelated plates' do
          let(:transfer_source_plates) { [create(:v2_plate, barcode_number: 4)] }

          it { is_expected.not_to be_valid }
        end
      end

      context 'where a child plate is missing' do
        let(:scanned_layout) { { 'bed1_barcode' => [source_1_barcode], 'bed6_barcode' => [target_2_barcode] } }

        it { is_expected.not_to be_valid }
      end

      context 'where a plate has an incorrect purpose' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_1_barcode],
            'bed5_barcode' => [target_1_barcode],
            'bed6_barcode' => [target_2_barcode]
          }
        end

        context 'for parent' do
          let(:source_purpose_name) { 'Incorrect Purpose' }

          it { is_expected.not_to be_valid }
        end

        context 'for child' do
          let(:target_1_purpose_name) { 'Incorrect Purpose' }

          it { is_expected.not_to be_valid }
        end
      end

      context 'where a plate has an incorrect state' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_1_barcode],
            'bed5_barcode' => [target_1_barcode],
            'bed6_barcode' => [target_2_barcode]
          }
        end

        context 'for parent' do
          before { source_plate_1.state = 'failed' }

          it { is_expected.not_to be_valid }
        end

        context 'for child' do
          before { target_plate_1.state = 'failed' }

          it { is_expected.not_to be_valid }
        end
      end
    end

    context 'with multiple parents' do
      let(:source_plate_2_uuid) { SecureRandom.uuid }
      let(:source_plate_2_attributes) do
        {
          uuid: source_plate_2_uuid,
          barcode_number: 5,
          purpose_name: source_purpose_name,
          purpose_uuid: source_purpose_uuid,
          state: source_plate_state
        }
      end

      let(:source_2_barcode) { source_plate_2.human_barcode }
      let(:source_plate_2) { create :v2_plate, source_plate_2_attributes }
      let(:transfer_source_plates) { [source_plate_1, source_plate_2] }

      let(:target_1_wells) do
        %w[C1 D1].map { |location| create :v2_well, location: location, upstream_plates: [transfer_source_plates[1]] } +
          %w[A1 B1].map { |location| create :v2_well, location: location, upstream_plates: [transfer_source_plates[0]] }
      end

      before { bed_plate_lookup(source_plate_2, [:purpose, { wells: :upstream_plates }]) }

      context 'with a valid layout' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_1_barcode],
            'bed2_barcode' => [source_2_barcode],
            'bed5_barcode' => [target_1_barcode],
            'bed6_barcode' => [target_2_barcode]
          }
        end

        context 'and related plates' do
          it { is_expected.to be_valid }
        end
      end

      context 'with source plates swapped around' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_2_barcode],
            'bed2_barcode' => [source_1_barcode],
            'bed5_barcode' => [target_1_barcode],
            'bed6_barcode' => [target_2_barcode]
          }
        end

        context 'and related plates' do
          it { is_expected.not_to be_valid }
        end
      end

      context 'with destination plates swapped around' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_1_barcode],
            'bed2_barcode' => [source_2_barcode],
            'bed5_barcode' => [target_2_barcode],
            'bed6_barcode' => [target_1_barcode]
          }
        end

        context 'and related plates' do
          it { is_expected.not_to be_valid }
        end
      end

      context 'with an extra unconnected source plate' do
        let(:unconnected_plate_3_uuid) { SecureRandom.uuid }
        let(:unconnected_plate_3_attributes) do
          {
            uuid: unconnected_plate_3_uuid,
            barcode_number: 6,
            purpose_name: source_purpose_name,
            purpose_uuid: source_purpose_uuid,
            state: source_plate_state
          }
        end

        let(:unconnected_plate_3_barcode) { unconnected_plate_3.human_barcode }
        let(:unconnected_plate_3) { create :v2_plate, unconnected_plate_3_attributes }

        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_1_barcode],
            'bed2_barcode' => [source_2_barcode],
            'bed3_barcode' => [unconnected_plate_3_barcode],
            'bed5_barcode' => [target_1_barcode],
            'bed6_barcode' => [target_2_barcode]
          }
        end

        before { bed_plate_lookup(unconnected_plate_3, [:purpose, { wells: :upstream_plates }]) }

        context 'and related plates' do
          it { is_expected.not_to be_valid }
        end
      end
    end
  end

  describe '#perform_transfer' do
    let(:scanned_layout) do
      {
        'bed1_barcode' => [source_1_barcode],
        'bed5_barcode' => [target_1_barcode],
        'bed6_barcode' => [target_2_barcode]
      }
    end

    let(:state_changes_attributes) do
      [
        {
          contents: nil,
          customer_accepts_responsibility: false,
          reason: 'Robot Pooling And Splitting Robot started',
          target_state: 'passed',
          target_uuid: target_plate_1_uuid,
          user_uuid: user_uuid
        },
        {
          contents: nil,
          customer_accepts_responsibility: false,
          reason: 'Robot Pooling And Splitting Robot started',
          target_state: 'passed',
          target_uuid: target_plate_2_uuid,
          user_uuid: user_uuid
        }
      ]
    end

    it 'performs transfers from started to passed for all destination plates' do
      expect_state_change_creation

      robot.perform_transfer(scanned_layout)
    end
  end
end
