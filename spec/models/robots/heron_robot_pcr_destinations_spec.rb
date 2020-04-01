# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::HeronRobotPcrDestinations, robots: true do
  include RobotHelpers

  has_a_working_api

  let(:user_uuid)                   { SecureRandom.uuid }

  # set up source plate
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
  let(:bed_4_PCR_plate_barcode) { source_plate.barcode.human + '-PP1' }
  let(:bed_6_PCR_plate_barcode) { source_plate.barcode.human + '-PP2' }
  let(:bed_4_PCR_plate_barcode_2) { source_plate_2.barcode.human + '-PP1' }
  let(:bed_6_PCR_plate_barcode_2) { source_plate_2.barcode.human + '-PP2' }

  # set up robot config
  let(:robot_spec) do
    {
      'name' => 'Bravo LHR RT => LHR PCR 1 and 2',
      'layout' => 'bed',
      'beds' => {
        'bed9_barcode' => {
          'purpose' => 'LHR RT', 'states' => ['passed'], 'label' => 'Bed 9'
        },
        'bed4_barcode' => {
          'purpose' => 'LHR RT', 'states' => ['passed'], 'label' => 'Bed 4',
          'display_purpose' => 'LHR PCR 1', 'override_class' => 'Robots::Bed::Heron', 'expected_plate_barcode_suffix' => 'PP1'
        },
        'bed6_barcode' => {
          'purpose' => 'LHR RT', 'states' => ['passed'], 'label' => 'Bed 6',
          'display_purpose' => 'LHR PCR 2', 'override_class' => 'Robots::Bed::Heron', 'expected_plate_barcode_suffix' => 'PP2'
        }
      },
      'class' => 'Robots::HeronRobotPcrDestinations'
    }
  end

  # set up robot
  let(:robot) { Robots::HeronRobotPcrDestinations.new(robot_spec.merge('api': api, 'user_uuid': user_uuid)) }

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

    context 'with all beds filled correctly' do
      let(:scanned_layout) do
        { 'bed9_barcode' => [source_barcode],
          'bed4_barcode' => [bed_4_PCR_plate_barcode],
          'bed6_barcode' => [bed_6_PCR_plate_barcode]
        }
      end

      it 'should be valid' do
        is_expected.to be_valid
      end
    end

    context 'when PCR plates have different barcodes from RT plate' do
      let(:scanned_layout) do
        { 'bed9_barcode' => [source_barcode],
          'bed4_barcode' => [bed_4_PCR_plate_barcode_2],
          'bed6_barcode' => [bed_6_PCR_plate_barcode_2] }
      end

      it 'should not be valid' do
        is_expected.not_to be_valid
        expect(subject.message).to include "The PCR plates must have the same barcode as the RT plate, plus a PP suffix."
      end
    end
  end
end
