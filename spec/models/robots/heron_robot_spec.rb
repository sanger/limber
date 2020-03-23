# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::HeronRobot, robots: true do
  include RobotHelpers

  has_a_working_api

  let(:source_plate_attributes) do
    {
      uuid: plate_uuid,
      barcode_number: 1234,
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
      barcode_number: 5678,
      # parents: target_plate_parents,
      wells: wells
    }
  end

  let(:user_uuid)                   { SecureRandom.uuid }
  let(:plate_uuid)                  { SecureRandom.uuid }
  let(:target_plate_uuid)           { SecureRandom.uuid }
  let(:source_barcode)              { source_plate.human_barcode }
  let(:source_barcode_alt)          { 'DN1S' }
  let(:source_purpose_name)         { 'LHR Cherrypick' }
  let(:source_purpose_uuid)         { SecureRandom.uuid }
  let(:source_plate_state)          { 'passed' }
  let(:source_plate) do
    create :v2_plate, source_plate_attributes
  end

  let(:target_barcode)              { target_plate.human_barcode }
  let(:target_purpose_name)         { 'LHR XP' }
  let(:target_purpose_uuid)         { SecureRandom.uuid }
  let(:target_plate) do
    create :v2_plate, target_plate_attributes 
  end
  # let(:target_plate_parents) { [source_plate] }
  # let(:target_plate_parent) { source_plate }
  
#   let(:custom_metadatum_collection) { create :custom_metadatum_collection, metadata: metadata }
#   let(:metadata) { { 'other_key' => 'value' } }

  let(:robot) { Robots::HeronRobot.new(robot_spec.merge('api': api, 'user_uuid': user_uuid)) }

# 'bed1_barcode' => {"purpose"=>"LHR Cherrypick", "states"=>["passed"], "label"=>"Bed 1", "child"=>"580000009659", "display_purpose"=>"LHR PCR 1", "override_class"=>"Robots::Bed::Heron", "expected_plate_barcode_suffix"=>"PP1"}

  let(:robot_spec) do
    {
      'name' => 'NX-96 LHR Cherrypick => LHR XP',
      'layout' => 'bed',
      'beds' => {
        'bed1_barcode' => {
          'purpose' => 'LHR Cherrypick', 'states' => ['passed'], 'child' => 'bed9_barcode', 'label' => 'Bed 1', 'display_purpose' => 'LHR PCR 1', 'override_class' => 'Robots::Bed::Heron', 'expected_plate_barcode_suffix' => 'PP1'
        },
        'bed2_barcode' => {
          'purpose' => 'LHR Cherrypick', 'states' => ['passed'], 'child' => 'bed9_barcode', 'label' => 'Bed 2', 'display_purpose' => 'LHR PCR 2', 'override_class' => 'Robots::Bed::Heron', 'expected_plate_barcode_suffix' => 'PP2'
        },
        'bed3_barcode' => {
          'purpose' => 'LHR Cherrypick', 'states' => ['passed'], 'child' => 'bed11_barcode', 'label' => 'Bed 3', 'display_purpose' => 'LHR PCR 1', 'override_class' => 'Robots::Bed::Heron', 'expected_plate_barcode_suffix' => 'PP1'
        },
        'bed4_barcode' => {
          'purpose' => 'LHR Cherrypick', 'states' => ['passed'], 'child' => 'bed11_barcode', 'label' => 'Bed 4', 'display_purpose' => 'LHR PCR 2', 'override_class' => 'Robots::Bed::Heron', 'expected_plate_barcode_suffix' => 'PP2'
        },
        'bed9_barcode' => {
          'purpose' => 'LHR XP', 'states' => ['pending'], target_state: 'passed', 'label' => 'Bed 9'
        },
        'bed11_barcode' => {
          'purpose' => 'LHR XP', 'states' => ['pending'], target_state: 'passed', 'label' => 'Bed 11'
        },
        # bed 9/ 11
      },
      'class' => 'Robots::HeronRobot'
    }
  end

  let(:robot_id) { 'nx-96-lhr-cherrypick-to-lhr-xp' }

  let(:transfer_source_plates) { [source_plate] } # plural?

  let(:wells) do
    %w[C1 D1].map do |location|
      create :v2_well, location: location, upstream_plates: transfer_source_plates
    end
  end

  before do
    create :purpose_config, uuid: source_purpose_uuid, name: source_purpose_name
    create :purpose_config, uuid: target_purpose_uuid, name: target_purpose_name

    # stub_api_get(target_plate_uuid, 'creation_transfers',
    #              body: json(:creation_transfer_collection,
    #                         destination: associated(:plate, target_plate_attributes),
    #                         sources: transfer_source_plates,
    #                         associated_on: 'creation_transfers',
    #                         transfer_factory: :creation_transfer))

    # bed_plate_lookup(source_plate, [:purpose, { wells: :upstream_plates }])
    # bed_plate_lookup(target_plate, [:purpose, { wells: :upstream_plates }])

    
    # bed_plate_lookup(source_plate)
    # bed_plate_lookup(target_plate)
  end

  describe '#verify' do
    subject { robot.verify(bed_plates: scanned_layout) }

    before do 
      bed_plate_lookup(source_plate)
      bed_plate_lookup(target_plate)
    end

    context 'with an known PCR plate' do
      let(:scanned_layout) { { 'bed1_barcode' => ['DN1234K-PP1'] } }
      
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

  #  TODO: make tests more realistic with two beds to beds 9/11
  #   context 'with a valid layout' do
  #     let(:scanned_layout) { { 'bed1_barcode' => [source_barcode], 'bed5_barcode' => [target_barcode] } }
  #   end

  end

#   describe '#perform_transfer' do
#     let(:state_change_request) do
#       stub_api_post('state_changes',
#                     payload: {
#                       state_change: {
#                         target_state: 'passed',
#                         reason: 'Robot Pooling Robot started',
#                         customer_accepts_responsibility: false,
#                         target: target_plate_uuid,
#                         user: user_uuid,
#                         contents: nil
#                       }
#                     },
#                     body: json(:state_change, target_state: 'passed'))
#     end

#     before do
#       state_change_request
#     end

#     it 'performs transfer from started to passed' do
#       robot.perform_transfer('bed1_barcode' => [source_barcode], 'bed5_barcode' => [target_barcode])
#       expect(state_change_request).to have_been_requested
#     end
#   end
end
