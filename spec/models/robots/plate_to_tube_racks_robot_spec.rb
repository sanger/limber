# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::PlateToTubeRacksRobot, :robot do
  include FeatureHelpers # Include methods for stubbing Sequencescape API requests.
  include RobotHelpers # Include methods for stubbing bed labware lookups.
  has_a_working_api # Add a mock Sequencescape API to the test context.

  # user_uuid
  let(:user_uuid) { 'user_uuid' }

  # tube rack barcodes
  let(:tube_rack1_barcode) { 'TR1F' }
  let(:tube_rack2_barcode) { 'TR2G' }

  # tube uuids
  let(:tube1_uuid) { 'tube1_uuid' }
  let(:tube2_uuid) { 'tube2_uuid' }
  let(:tube3_uuid) { 'tube3_uuid' }
  let(:tube4_uuid) { 'tube4_uuid' }
  let(:tube5_uuid) { 'tube5_uuid' }
  let(:tube6_uuid) { 'tube6_uuid' }

  let(:tube_uuids) { [tube1_uuid, tube2_uuid, tube3_uuid, tube4_uuid, tube5_uuid, tube6_uuid] }

  # tube purpose uuids
  let(:tube_purpose1_uuid) { 'tube_purpose1_uuid' }
  let(:tube_purpose2_uuid) { 'tube_purpose2_uuid' }

  # tube purpose names
  let(:tube_purpose1_name) { 'tube_purpose1_name' }
  let(:tube_purpose2_name) { 'tube_purpose2_name' }

  # tube purposes
  let(:tube_purpose1) { create(:v2_purpose, name: tube_purpose1_name, uuid: tube_purpose1_uuid) }
  let(:tube_purpose2) { create(:v2_purpose, name: tube_purpose2_name, uuid: tube_purpose2_uuid) }

  # tube states
  let(:tube1_state) { 'pending' }
  let(:tube2_state) { 'pending' }
  let(:tube3_state) { 'pending' }
  let(:tube4_state) { 'pending' }
  let(:tube5_state) { 'pending' }
  let(:tube6_state) { 'pending' }

  # tubes
  let(:tube1) do
    create(
      :v2_tube_with_metadata,
      uuid: tube1_uuid,
      barcode_prefix: 'FX',
      barcode_number: 4,
      custom_metadatum_collection: tube1_custom_metadatum_collection,
      purpose: tube_purpose1,
      state: tube1_state
    )
  end
  let(:tube2) do
    create(
      :v2_tube_with_metadata,
      uuid: tube2_uuid,
      barcode_prefix: 'FX',
      barcode_number: 5,
      custom_metadatum_collection: tube2_custom_metadatum_collection,
      purpose: tube_purpose1,
      state: tube2_state
    )
  end
  let(:tube3) do
    create(
      :v2_tube_with_metadata,
      uuid: tube3_uuid,
      barcode_prefix: 'FX',
      barcode_number: 6,
      custom_metadatum_collection: tube3_custom_metadatum_collection,
      purpose: tube_purpose1,
      state: tube3_state
    )
  end
  let(:tube4) do
    create(
      :v2_tube_with_metadata,
      uuid: tube4_uuid,
      barcode_prefix: 'FX',
      barcode_number: 7,
      custom_metadatum_collection: tube4_custom_metadatum_collection,
      purpose: tube_purpose2,
      state: tube4_state
    )
  end
  let(:tube5) do
    create(
      :v2_tube_with_metadata,
      uuid: tube5_uuid,
      barcode_prefix: 'FX',
      barcode_number: 8,
      custom_metadatum_collection: tube5_custom_metadatum_collection,
      purpose: tube_purpose2,
      state: tube5_state
    )
  end
  let(:tube6) do
    create(
      :v2_tube_with_metadata,
      uuid: tube6_uuid,
      barcode_prefix: 'FX',
      barcode_number: 9,
      custom_metadatum_collection: tube6_custom_metadatum_collection,
      purpose: tube_purpose2,
      state: tube6_state
    )
  end

  # tube rack purpose uuids
  let(:tube_rack1_purpose_uuid) { 'tube_rack1_purpose_uuid' }
  let(:tube_rack2_purpose_uuid) { 'tube_rack2_purpose_uuid' }

  # tube rack purpose names
  let(:tube_rack1_purpose_name) { 'tube_rack1_purpose_name' }
  let(:tube_rack2_purpose_name) { 'tube_rack2_purpose_name' }

  # tube rack purposes
  let(:tube_rack1_purpose) do
    create(:v2_tube_rack_purpose, name: tube_rack1_purpose_name, uuid: tube_rack1_purpose_uuid)
  end
  let(:tube_rack2_purpose) do
    create(:v2_tube_rack_purpose, name: tube_rack2_purpose_name, uuid: tube_rack2_purpose_uuid)
  end

  # tube rack uuids
  let(:tube_rack1_uuid) { 'tube_rack1_uuid' }
  let(:tube_rack2_uuid) { 'tube_rack2_uuid' }

  # tube racks
  let!(:tube_rack1) do
    create(
      :tube_rack,
      purpose: tube_rack1_purpose,
      barcode_number: 1,
      barcode_prefix: 'TR',
      uuid: tube_rack1_uuid,
      tubes: {
        A1: tube1,
        B1: tube2,
        C1: tube3
      },
      parents: [plate]
    )
  end
  let!(:tube_rack2) do
    create(
      :tube_rack,
      purpose: tube_rack2_purpose,
      barcode_number: 2,
      barcode_prefix: 'TR',
      uuid: tube_rack2_uuid,
      tubes: {
        A1: tube4,
        B1: tube5,
        C1: tube6
      },
      parents: [plate]
    )
  end

  # tube metadata
  let(:tube1_metadata) { { 'tube_rack_barcode' => tube_rack1_barcode, 'tube_rack_position' => 'A1' } }
  let(:tube2_metadata) { { 'tube_rack_barcode' => tube_rack1_barcode, 'tube_rack_position' => 'B1' } }
  let(:tube3_metadata) { { 'tube_rack_barcode' => tube_rack1_barcode, 'tube_rack_position' => 'C1' } }
  let(:tube4_metadata) { { 'tube_rack_barcode' => tube_rack2_barcode, 'tube_rack_position' => 'A1' } }
  let(:tube5_metadata) { { 'tube_rack_barcode' => tube_rack2_barcode, 'tube_rack_position' => 'B1' } }
  let(:tube6_metadata) { { 'tube_rack_barcode' => tube_rack2_barcode, 'tube_rack_position' => 'C1' } }

  # tube custom metadata collections
  let(:tube1_custom_metadatum_collection) { create(:custom_metadatum_collection, metadata: tube1_metadata) }
  let(:tube2_custom_metadatum_collection) { create(:custom_metadatum_collection, metadata: tube2_metadata) }
  let(:tube3_custom_metadatum_collection) { create(:custom_metadatum_collection, metadata: tube3_metadata) }
  let(:tube4_custom_metadatum_collection) { create(:custom_metadatum_collection, metadata: tube4_metadata) }
  let(:tube5_custom_metadatum_collection) { create(:custom_metadatum_collection, metadata: tube5_metadata) }
  let(:tube6_custom_metadatum_collection) { create(:custom_metadatum_collection, metadata: tube6_metadata) }

  # wells
  let(:well1) { create(:v2_well, location: 'A1', downstream_tubes: [tube1, tube4]) }
  let(:well2) { create(:v2_well, location: 'B1', downstream_tubes: [tube2, tube5]) }
  let(:well3) { create(:v2_well, location: 'C1', downstream_tubes: [tube3, tube6]) }

  # plate purpose uuid
  let(:plate_purpose_uuid) { 'plate_purpose_uuid' }

  # plate purpose name
  let(:plate_purpose_name) { 'plate_purpose_name' }

  # plate purpose
  let(:plate_purpose) { create(:v2_purpose, name: plate_purpose_name, uuid: plate_purpose_uuid) }

  # plate state
  let(:plate_state) { 'passed' }

  # plate
  let(:plate) do
    create(:v2_plate, wells: [well1, well2, well3], barcode_number: 3, purpose: plate_purpose, state: plate_state)
  end

  # bed barcodes
  let(:bed1_barcode) { 'bed1_barcode' }
  let(:bed2_barcode) { 'bed2_barcode' }
  let(:bed3_barcode) { 'bed3_barcode' }

  # bed purposes: same as plate and tube-rack purposes by default
  let(:config_plate_purpose) { plate_purpose_name }
  let(:config_tube_rack1_purpose) { tube_rack1_purpose_name }
  let(:config_tube_rack2_purpose) { tube_rack2_purpose_name }

  let(:robot_name) { 'robot_name' }

  let(:robot_config) do
    {
      :name => robot_name,
      :verify_robot => false,
      :beds => {
        bed1_barcode => {
          purpose: config_plate_purpose,
          states: ['passed'],
          label: 'Bed 1'
        },
        bed2_barcode => {
          purpose: config_tube_rack1_purpose,
          states: ['pending'],
          label: 'Bed 2',
          target_state: 'passed'
        },
        bed3_barcode => {
          purpose: config_tube_rack2_purpose,
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed'
        }
      },
      'class' => 'Robots::PlateToTubeRacksRobot',
      :relationships => [
        {
          'type' => 'relationship_type',
          'options' => {
            'parent' => bed1_barcode,
            'children' => [bed2_barcode, bed3_barcode]
          }
        }
      ]
    }
  end

  let(:robot) { described_class.new(robot_config.merge(api:, user_uuid:)) }

  let(:scanned_layout) do
    {
      bed1_barcode => [plate.human_barcode],
      bed2_barcode => [tube_rack1_barcode],
      bed3_barcode => [tube_rack2_barcode]
    }
  end

  before do
    # Stub robot request to the Sequencescape API to look up the parent plate
    plate_includes = described_class::PLATE_INCLUDES
    bed_plate_lookup_with_barcode(plate.barcode.human, [plate], plate_includes)

    # Stub robot requests to the Sequencescape API to look up tube-racks as if plates, should return empty
    bed_plate_lookup_with_barcode(tube_rack1_barcode, [], plate_includes)
    bed_plate_lookup_with_barcode(tube_rack2_barcode, [], plate_includes)

    # Stub robot requests to the Sequencescape API to look up tube-racks
    tube_rack_includes = Sequencescape::Api::V2::TubeRack::DEFAULT_TUBE_RACK_INCLUDES
    bed_tube_rack_lookup_with_uuid(tube_rack1.uuid, [tube_rack1], tube_rack_includes) if tube_rack1
    bed_tube_rack_lookup_with_uuid(tube_rack2.uuid, [tube_rack2], tube_rack_includes)

    # Set up children of plate
    allow(plate).to receive(:children).and_return([tube_rack1, tube_rack2])
  end

  describe '#verify' do
    # The robot will receive the scanned layout as bed_labwares from request parameters
    # and return a report object showing the validity of each bed and robot.
    subject { robot.verify(bed_labwares: scanned_layout) }

    context 'with two destination purposes' do
      # Parent plate has two child tube-racks. We validate parent bed (bed1)
      # and two child beds (bed2 and bed3).
      context 'with a valid scanned layout' do
        it { is_expected.to be_valid }
      end

      context 'with plate on an unknown bed' do
        # Plate is on a bed we are not supposed to use for any labware.
        let(:unknown_bed_barcode) { 'unknown_bed_barcode' }
        let(:scanned_layout) do
          {
            unknown_bed_barcode => [plate.human_barcode],
            bed2_barcode => [tube_rack1_barcode],
            bed3_barcode => [tube_rack2_barcode]
          }
        end

        it { is_expected.not_to be_valid }

        it 'has correct error messages' do
          errors = [
            "#{unknown_bed_barcode} does not appear to be a valid bed barcode.",
            'Bed 1: should not be empty.',
            'Bed 1: should have children.'
          ]
          errors.each { |error| expect(subject.message).to include(error) }
        end
      end

      context 'with a plate missing' do
        # We forgot to scan the plate.
        let(:scanned_layout) { { bed2_barcode => [tube_rack1_barcode], bed3_barcode => [tube_rack2_barcode] } }

        it { is_expected.not_to be_valid }

        it 'has correct error messages' do
          # The following errors are expected because we could not find the plate.
          expected_errors = ['Bed 1: should not be empty.', 'Bed 1: should have children.']
          expected_errors.each { |error| expect(subject.message).to include(error) }
        end
      end

      context 'with a child tube-rack missing' do
        # We forgot to scan the second tube-rack.
        let(:scanned_layout) { { bed1_barcode => [plate.human_barcode], bed2_barcode => [tube_rack1_barcode] } }

        it { is_expected.not_to be_valid }

        it 'has correct error messages' do
          errors = [
            "Bed 3: Was expected to contain labware barcode #{tube_rack2_barcode} but nothing was scanned (empty)."
          ]
          errors.each { |error| expect(subject.message).to include(error) }
        end
      end

      context 'with all child tube-racks missing' do
        # We forgot to scan all tube-racks.
        let(:scanned_layout) { { bed1_barcode => [plate.human_barcode] } }

        it { is_expected.not_to be_valid }

        # code knows by comparing to the labware store which specific tube racks are missing
        it 'has correct error messages' do
          expected_errors = [
            "Bed 2: Was expected to contain labware barcode #{tube_rack1_barcode} but nothing was scanned (empty).",
            "Bed 3: Was expected to contain labware barcode #{tube_rack2_barcode} but nothing was scanned (empty)."
          ]
          expected_errors.each { |error| expect(subject.message).to include(error) }
        end
      end

      context 'with a tube-rack on an unknown bed' do
        # The second tube-rack is on a bed we are not supposed to use for any labware.
        let(:unknown_bed_barcode) { 'unknown_bed_barcode' }
        let(:scanned_layout) do
          {
            bed1_barcode => [plate.human_barcode],
            bed2_barcode => [tube_rack1_barcode],
            unknown_bed_barcode => [tube_rack2_barcode]
          }
        end

        it { is_expected.not_to be_valid }

        it 'has correct error messages' do
          errors = [
            "#{unknown_bed_barcode} does not appear to be a valid bed barcode.",
            "Bed 3: Was expected to contain labware barcode #{tube_rack2_barcode} but nothing was scanned (empty)."
          ]
          errors.each { |error| expect(subject.message).to include(error) }
        end
      end

      context 'with a plate that has an incorrect purpose' do
        # The plate has a purpose that does not match the expected bed purpose.
        let(:plate_purpose_name) { 'incorrect_purpose' }
        let(:config_plate_purpose) { 'plate_purpose_name' }

        it { is_expected.not_to be_valid }

        it 'has correct error messages' do
          errors = [
            "Bed 1 - Labware #{plate.barcode.human} is a #{plate_purpose_name} " \
            "not a #{config_plate_purpose} labware."
          ]
          errors.each { |error| expect(subject.message).to include(error) }
        end
      end
    end

    context 'with one destination purpose' do
      # Parent plate has only one child tube-rack. We validate parent bed
      # (bed1) and one child bed (bed3).
      # wells
      let(:well1) { create(:v2_well, location: 'A1', downstream_tubes: [tube4]) }
      let(:well2) { create(:v2_well, location: 'B1', downstream_tubes: [tube5]) }
      let(:well3) { create(:v2_well, location: 'C1', downstream_tubes: [tube6]) }

      let(:tube_rack1) { nil }

      before { allow(plate).to receive(:children).and_return([tube_rack2]) }

      context 'with a valid scanned layout' do
        let(:scanned_layout) { { bed1_barcode => [plate.human_barcode], bed3_barcode => [tube_rack2_barcode] } }

        it { is_expected.to be_valid }
      end
    end
  end

  describe '#perform_transfer' do
    let(:state_changes_attributes) do
      tube_uuids.map do |tube_uuid|
        {
          contents: nil,
          customer_accepts_responsibility: false,
          reason: "Robot #{robot_name} started",
          target_state: 'passed',
          target_uuid: tube_uuid,
          user_uuid: user_uuid
        }
      end
    end

    before do
      # Create purpose configs in Settings for state changers.
      create(:purpose_config, uuid: plate_purpose_uuid, name: plate_purpose_name)
      create(:purpose_config, uuid: tube_purpose1_uuid, name: tube_purpose1_name)
      create(:purpose_config, uuid: tube_purpose2_uuid, name: tube_purpose2_name)
    end

    it 'performs transfers for all tubes on the tube-racks' do
      expect_state_change_creation

      robot.perform_transfer(scanned_layout)
    end
  end
end
