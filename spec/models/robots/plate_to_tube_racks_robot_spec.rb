# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::PlateToTubeRacksRobot, robot: true do
  include FeatureHelpers # Include methods for stubbing Sequencescape API requests.
  include RobotHelpers # Include methods for stubbing bed labware lookups.
  has_a_working_api # Add a mock Sequencescape API to the test context.

  describe '#verify' do
    # The robot will receive the scanned layout as bed_labwares from request parameters
    # and return a report object showing the validity of each bed and robot.
    subject { robot.verify(bed_labwares: scanned_layout) }

    # user_uuid
    let(:user_uuid) { 'user_uuid' }

    # tube rack barcodes
    let(:tube_rack1_barcode) { 'TR00000001' }
    let(:tube_rack2_barcode) { 'TR00000002' }

    # tube metadata
    let(:tube1_metadata) { { 'tube_rack_barcode' => tube_rack1_barcode, 'tube_rack_position' => 'A1' } }
    let(:tube2_metadata) { { 'tube_rack_barcode' => tube_rack1_barcode, 'tube_rack_position' => 'B1' } }
    let(:tube3_metadata) { { 'tube_rack_barcode' => tube_rack1_barcode, 'tube_rack_position' => 'C1' } }
    let(:tube4_metadata) { { 'tube_rack_barcode' => tube_rack2_barcode, 'tube_rack_position' => 'A1' } }
    let(:tube5_metadata) { { 'tube_rack_barcode' => tube_rack2_barcode, 'tube_rack_position' => 'B1' } }
    let(:tube6_metadata) { { 'tube_rack_barcode' => tube_rack2_barcode, 'tube_rack_position' => 'C1' } }

    # tube custom metadata collections
    let(:tube1_custom_metadata) { create(:custom_metadatum_collection, metadata: tube1_metadata) }
    let(:tube2_custom_metadata) { create(:custom_metadatum_collection, metadata: tube2_metadata) }
    let(:tube3_custom_metadata) { create(:custom_metadatum_collection, metadata: tube3_metadata) }
    let(:tube4_custom_metadata) { create(:custom_metadatum_collection, metadata: tube4_metadata) }
    let(:tube5_custom_metadata) { create(:custom_metadatum_collection, metadata: tube5_metadata) }
    let(:tube6_custom_metadata) { create(:custom_metadatum_collection, metadata: tube6_metadata) }

    # tube uuids
    let(:tube1_uuid) { 'tube1_uuid' }
    let(:tube2_uuid) { 'tube2_uuid' }
    let(:tube3_uuid) { 'tube3_uuid' }
    let(:tube4_uuid) { 'tube4_uuid' }
    let(:tube5_uuid) { 'tube5_uuid' }
    let(:tube6_uuid) { 'tube6_uuid' }

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
        custom_metadatum_collection: tube1_custom_metadata,
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
        custom_metadatum_collection: tube2_custom_metadata,
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
        custom_metadatum_collection: tube3_custom_metadata,
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
        custom_metadatum_collection: tube4_custom_metadata,
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
        custom_metadatum_collection: tube5_custom_metadata,
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
        custom_metadatum_collection: tube6_custom_metadata,
        purpose: tube_purpose2,
        state: tube6_state
      )
    end

    # wells
    let(:well1) { create(:v2_well, location: 'A1', downstream_tubes: [tube1, tube4]) }
    let(:well2) { create(:v2_well, location: 'B1', downstream_tubes: [tube2, tube5]) }
    let(:well3) { create(:v2_well, location: 'C1', downstream_tubes: [tube3, tube6]) }

    # plate purpose uuid
    let(:plate_purpose_uuid) { 'plate_purpose_uuid' }

    # plate purpose name
    let(:plate_purpose_name) { 'plate_purpose' }

    # plate purpose
    let(:plate_purpose) { create(:v2_purpose, name: plate_purpose_name, uuid: plate_purpose_uuid) }

    # plate uuid
    let(:plate_uuid) { 'plate_uuid' }

    # plate state
    let(:plate_state) { 'passed' }

    # plate
    let(:plate) do
      create(:v2_plate, wells: [well1, well2, well3], barcode_number: 3, purpose: plate_purpose, state: plate_state)
    end

    let(:bed1_barcode) { 'bed1_barcode' }
    let(:bed2_barcode) { 'bed2_barcode' }
    let(:bed3_barcode) { 'bed3_barcode' }

    let(:robot_config) do
      {
        name: 'robot_name',
        beds: {
          bed1_barcode => {
            purpose: plate_purpose_name,
            states: ['passed'],
            label: 'Bed 1'
          },
          bed2_barcode => {
            purpose: tube_purpose1_name,
            states: ['pending'],
            label: 'Bed 2',
            target_state: 'passed'
          },
          bed3_barcode => {
            purpose: tube_purpose2_name,
            states: ['pending'],
            label: 'Bed 3',
            target_state: 'passed'
          }
        },
        relationships: [
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

    let(:robot) { described_class.new(robot_config.merge(api: api, user_uuid: user_uuid)) }

    before do
      # Stub robot requests to the Sequencescape API to look up plate by
      # barcode. It returns the plate with its wells and downstream tubes.
      includes = 'purpose,wells,wells.downstream_tubes,wells.downstream_tubes.custom_metadatum_collection'
      bed_plate_lookup_with_barcode(plate.barcode.human, [plate], includes)
      bed_plate_lookup_with_barcode(tube_rack1_barcode, [], includes)
      bed_plate_lookup_with_barcode(tube_rack2_barcode, [], includes)
    end

    context 'with two destination purposes' do
      # Parent plate has two child tube-racks. We validate parent bed (bed1)
      # and two child beds (bed2 and bed3).
      context 'with a valid scanned layout' do
        let(:scanned_layout) do
          {
            bed1_barcode => [plate.human_barcode],
            bed2_barcode => [tube_rack1_barcode],
            bed3_barcode => [tube_rack2_barcode]
          }
        end

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

        it 'has correct messages' do
          errors = [
            "#{unknown_bed_barcode} does not appear to be a valid bed barcode.",
            'Bed 1: should not be empty.',
            'Bed 1: should have children.'
          ]
          errors.each { |error| expect(subject.message).to include(error) }
        end
      end

      context 'with a child tube-rack missing' do
        # We forgot to scan the second tube-rack.
        let(:scanned_layout) { { bed1_barcode => [plate.human_barcode], bed2_barcode => [tube_rack1_barcode] } }
        it { is_expected.not_to be_valid }

        it 'has correct messages' do
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

        it 'has correct messages' do
          errors = [
            "Bed 2: Was expected to contain labware barcode #{tube_rack1_barcode} but nothing was scanned (empty).",
            "Bed 3: Was expected to contain labware barcode #{tube_rack2_barcode} but nothing was scanned (empty)."
          ]
          errors.each { |error| expect(subject.message).to include(error) }
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

        it 'has correct messages' do
          errors = [
            "#{unknown_bed_barcode} does not appear to be a valid bed barcode.",
            "Bed 3: Was expected to contain labware barcode #{tube_rack2_barcode} but nothing was scanned (empty)."
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

      context 'with a valid scanned layout' do
        let(:scanned_layout) { { bed1_barcode => [plate.human_barcode], bed3_barcode => [tube_rack2_barcode] } }

        it { is_expected.to be_valid }
      end
    end
  end
end
