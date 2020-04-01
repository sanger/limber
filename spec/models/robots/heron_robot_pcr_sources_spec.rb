# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::HeronRobotPcrSources, robots: true do
  include RobotHelpers

  has_a_working_api

  let(:user_uuid)                   { SecureRandom.uuid }

  # set up source plates
  let(:source_purpose_name)         { 'LHR RT' }
  let(:source_purpose_uuid)         { SecureRandom.uuid }

  let(:source_plate_attributes) do
    {
      barcode_number: 1234,
      purpose_name: source_purpose_name,
      purpose_uuid: source_purpose_uuid,
      state: 'passed'
    }
  end
  let(:source_plate_2_attributes) do
    {
      barcode_number: 1111,
      purpose_name: source_purpose_name,
      purpose_uuid: source_purpose_uuid,
      state: 'passed'
    }
  end

  let(:source_plate) do
    create :v2_plate, source_plate_attributes
  end
  let(:source_plate_2) do
    create :v2_plate, source_plate_2_attributes
  end

  let(:source_barcode)              { source_plate.human_barcode }
  let(:source_2_barcode)            { source_plate.human_barcode }

  # set up target plates
  let(:target_purpose_name)         { 'LHR XP' }
  let(:target_purpose_uuid)         { SecureRandom.uuid }

  let(:target_plate_parents) { [source_plate] }
  let(:target_plate_2_parents) { [source_plate_2] }

  let(:target_plate_attributes) do
    {
      purpose_name: target_purpose_name,
      purpose_uuid: target_purpose_uuid,
      barcode_number: 5678,
      parents: target_plate_parents
    }
  end
  let(:target_plate_2_attributes) do
    {
      purpose_name: target_purpose_name,
      purpose_uuid: target_purpose_uuid,
      barcode_number: 2222,
      parents: target_plate_2_parents
    }
  end

  let(:target_plate) do
    create :v2_plate, target_plate_attributes
  end
  let(:target_plate_2) do
    create :v2_plate, target_plate_2_attributes
  end

  let(:target_barcode)              { target_plate.human_barcode }
  let(:target_2_barcode)            { target_plate_2.human_barcode }

  # set up PCR plates (barcodes only, as plates are not tracked)
  let(:bed_1_PCR_plate_barcode) { source_plate.barcode.human + '-PP1' }
  let(:bed_2_PCR_plate_barcode) { source_plate.barcode.human + '-PP2' }
  let(:bed_3_PCR_plate_barcode) { source_plate_2.barcode.human + '-PP1' }
  let(:bed_4_PCR_plate_barcode) { source_plate_2.barcode.human + '-PP2' }

  # set up robot config
  let(:robot_spec) do
    {
      'name' => 'NX-96 LHR PCR 1 and 2 => LHR XP',
      'layout' => 'bed',
      'beds' => {
        'bed1_barcode' => {
          'purpose' => 'LHR RT', 'states' => ['passed'], 'child' => 'bed9_barcode', 'label' => 'Bed 1',
          'display_purpose' => 'LHR PCR 1', 'override_class' => 'Robots::Bed::Heron', 'expected_plate_barcode_suffix' => 'PP1'
        },
        'bed2_barcode' => {
          'purpose' => 'LHR RT', 'states' => ['passed'], 'child' => 'bed9_barcode', 'label' => 'Bed 2',
          'display_purpose' => 'LHR PCR 2', 'override_class' => 'Robots::Bed::Heron', 'expected_plate_barcode_suffix' => 'PP2'
        },
        'bed3_barcode' => {
          'purpose' => 'LHR RT', 'states' => ['passed'], 'child' => 'bed11_barcode', 'label' => 'Bed 3',
          'display_purpose' => 'LHR PCR 1', 'override_class' => 'Robots::Bed::Heron', 'expected_plate_barcode_suffix' => 'PP1'
        },
        'bed4_barcode' => {
          'purpose' => 'LHR RT', 'states' => ['passed'], 'child' => 'bed11_barcode', 'label' => 'Bed 4',
          'display_purpose' => 'LHR PCR 2', 'override_class' => 'Robots::Bed::Heron', 'expected_plate_barcode_suffix' => 'PP2'
        },
        'bed9_barcode' => {
          'purpose' => 'LHR XP', 'parents' => %w[bed1_barcode bed2_barcode], 'states' => ['pending'], target_state: 'passed', 'label' => 'Bed 9'
        },
        'bed11_barcode' => {
          'purpose' => 'LHR XP', 'parents' => %w[bed3_barcode bed4_barcode], 'states' => ['pending'], target_state: 'passed', 'label' => 'Bed 11'
        }
      },
      'class' => 'Robots::HeronRobotPcrSources'
    }
  end

  # set up robot
  let(:robot) { Robots::HeronRobotPcrSources.new(robot_spec.merge('api': api, 'user_uuid': user_uuid)) }

  before do
    create :purpose_config, uuid: source_purpose_uuid, name: source_purpose_name
    create :purpose_config, uuid: target_purpose_uuid, name: target_purpose_name
  end

  describe '#verify' do
    subject { robot.verify(bed_plates: scanned_layout) }

    before do
      bed_plate_lookup(source_plate)
      bed_plate_lookup(source_plate_2)
      bed_plate_lookup(target_plate)
      bed_plate_lookup(target_plate_2)
    end

    context 'with beds 1&2 -> 9' do
      let(:scanned_layout) do
        { 'bed1_barcode' => [bed_1_PCR_plate_barcode],
          'bed2_barcode' => [bed_2_PCR_plate_barcode],
          'bed9_barcode' => [target_barcode] }
      end

      it 'should be valid' do
        is_expected.to be_valid
      end
    end

    context 'with all beds filled' do
      let(:scanned_layout) do
        { 'bed1_barcode' => [bed_1_PCR_plate_barcode],
          'bed2_barcode' => [bed_2_PCR_plate_barcode],
          'bed9_barcode' => [target_barcode],
          'bed3_barcode' => [bed_3_PCR_plate_barcode],
          'bed4_barcode' => [bed_4_PCR_plate_barcode],
          'bed11_barcode' => [target_2_barcode] }
      end

      it 'should be valid' do
        is_expected.to be_valid
      end
    end

    context 'when the PCR plate barcode suffix is unknown for bed 1' do
      let(:scanned_layout) { { 'bed1_barcode' => ['DN1234K-PPX'] } }

      it 'should not be valid' do
        is_expected.not_to be_valid
        expect(subject.message).to include 'Bed 1 - Expected plate barcode to end in the following suffix: PP1'
      end
    end

    context 'when the PCR plate barcode suffix is unknown for bed 2' do
      let(:scanned_layout) { { 'bed2_barcode' => ['DN1234K-PPX'] } }

      it 'should not be valid' do
        is_expected.not_to be_valid
        expect(subject.message).to include 'Bed 2 - Expected plate barcode to end in the following suffix: PP2'
      end
    end

    context 'when the PCR plate barcode suffix is missing' do
      let(:scanned_layout) { { 'bed1_barcode' => ['DN1234K'] } }

      it 'should not be valid' do
        is_expected.not_to be_valid
        expect(subject.message).to include 'Bed 1 - Expected plate barcode to end in the following suffix: PP1'
      end
    end

    context 'when the PCR plate barcode is unknown' do
      before do
        bed_plate_lookup_with_barcode('DNxxxK', [])
      end

      let(:scanned_layout) { { 'bed2_barcode' => ['DNxxxK-PP1'] } }

      it 'should not be valid' do
        is_expected.not_to be_valid
        expect(subject.message).to include "Bed 2 - Plate Could not find a plate with the barcode 'DNxxxK'"
      end
    end

    context 'when beds 1&2 have different barcodes' do
      let(:scanned_layout) do
        { 'bed1_barcode' => [bed_1_PCR_plate_barcode],
          'bed2_barcode' => [bed_4_PCR_plate_barcode],
          'bed9_barcode' => [target_barcode] }
      end

      it 'should not be valid' do
        is_expected.not_to be_valid
        expect(subject.message).to include "Bed 2: Should contain #{source_barcode}"
      end
    end
  end

  describe '#perform_transfer' do
    let(:state_change_request) do
      stub_api_post('state_changes',
                    payload: {
                      state_change: {
                        target_state: 'passed',
                        reason: 'Robot NX-96 LHR PCR 1 and 2 => LHR XP started',
                        customer_accepts_responsibility: false,
                        target: target_plate.uuid,
                        user: user_uuid,
                        contents: nil
                      }
                    },
                    body: json(:state_change, target_state: 'passed'))
    end

    before do
      state_change_request
      bed_plate_lookup(source_plate)
      bed_plate_lookup(target_plate)
    end

    it 'performs transfer from started to passed' do
      robot.perform_transfer(
        'bed1_barcode' => [bed_1_PCR_plate_barcode],
        'bed2_barcode' => [bed_2_PCR_plate_barcode],
        'bed9_barcode' => [target_barcode]
      )

      expect(state_change_request).to have_been_requested
    end
  end
end
