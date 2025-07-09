# frozen_string_literal: true

require 'spec_helper'
# From UAT Actions
# 1. Create Plate
# 2. Update Manifest
# 3. Create Submission

RSpec.describe LabwareCreators::CardinalPoolsPlate, :cardinal do
  subject { described_class.new(form_attributes) }

  let(:dest_purpose_uuid) { 'dest-purpose' }
  let(:parent_uuid) { 'example-parent-uuid' }
  let(:user_uuid) { 'user-uuid' }
  let(:plate_size) { 96 }
  let(:child_uuid) { 'example-dest-uuid' }
  let(:child_plate) { create(:v2_plate, uuid: child_uuid, well_count: plate_size) }

  let(:form_attributes) { { purpose_uuid: dest_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  # TODO: rename throughout to source and dest
  # SS V2 API Plate
  let(:parent_plate) do
    plate = create(:v2_plate, uuid: parent_uuid, well_count: plate_size, aliquots_without_requests: 1)

    collected_by_group1 = plate.wells[0..9]
    collected_by_group1.each do |well|
      well.aliquots.first.sample.sample_metadata.collected_by = 'collected by location 1'
    end

    collected_by_group2 = plate.wells[9..49]
    collected_by_group2.each do |well|
      well.aliquots.first.sample.sample_metadata.collected_by = 'collected by location 2'
    end

    collected_by_group3 = plate.wells[49..95]
    collected_by_group3.each do |well|
      well.aliquots.first.sample.sample_metadata.collected_by = 'collected by location 3'
    end

    plate
  end

  before { stub_v2_plate(parent_plate, stub_search: false) }

  context 'on new' do
    it 'can be initialised' do
      expect(subject).to be_a described_class
    end

    it 'has the config loaded' do
      expect(Rails.application.config.cardinal_pooling_config[96]).to eq(8)
      expect(Rails.application.config.cardinal_pooling_config[87]).to eq(7)
      expect(Rails.application.config.cardinal_pooling_config[76]).to eq(6)
      expect(Rails.application.config.cardinal_pooling_config[65]).to eq(5)
      expect(Rails.application.config.cardinal_pooling_config[52]).to eq(4)
      expect(Rails.application.config.cardinal_pooling_config[39]).to eq(3)
      expect(Rails.application.config.cardinal_pooling_config[26]).to eq(2)
      expect(Rails.application.config.cardinal_pooling_config[20]).to eq(1)
    end

    context 'when missing sample metadata' do
      it 'fails validation when all wells are missing a sample metadata' do
        parent_plate.wells.each { |well| well.aliquots.first.sample.sample_metadata = nil }

        expect(subject).not_to be_valid
        expect(subject.errors.messages[:parent]).to be_present
      end

      it 'fails validation when 1 well is missing a sample metadata' do
        parent_plate.wells[0].aliquots.first.sample.sample_metadata = nil

        expect(subject).not_to be_valid
        expect(subject.errors.messages[:parent]).to be_present
      end

      it 'fails validation when the sample metadata: collected_by is missing' do
        parent_plate.wells[0].aliquots.first.sample.sample_metadata.collected_by = nil

        expect(subject).not_to be_valid
        expect(subject.errors.messages[:parent]).to be_present
      end
    end
  end

  describe '#passed_parent_wells' do
    context 'when the first 4 wells failed and the rest passed' do
      before do
        parent_plate.wells[..3].each { |well| well['state'] = 'failed' }
        parent_plate.wells[4..].each { |well| well['state'] = 'passed' }
      end

      it 'gets 92 passed wells' do
        expect(subject.passed_parent_wells.count).to eq(92)
      end
    end

    context 'when the first 5 wells failed and the rest passed' do
      before do
        parent_plate.wells[..4].each { |well| well['state'] = 'failed' }
        parent_plate.wells[5..].each { |well| well['state'] = 'passed' }
      end

      it 'gets 91 passed wells' do
        expect(subject.passed_parent_wells.count).to eq(91)
      end
    end
  end

  describe '#number_of_pools' do
    #  20 passed, 76 failed
    it 'has 1 pool' do
      parent_plate.wells[0..19].each { |well| well['state'] = 'passed' }
      expect(subject.number_of_pools).to eq(1)
    end

    #  21 passed, 75 failed
    it 'has 2 pools' do
      parent_plate.wells[0..20].each { |well| well['state'] = 'passed' }
      expect(subject.number_of_pools).to eq(2)
    end

    #  28 passed, 68 failed
    it 'has 3 pools' do
      parent_plate.wells[0..27].each { |well| well['state'] = 'passed' }
      expect(subject.number_of_pools).to eq(3)
    end

    #  40 passed, 56 failed
    it 'has 4 pools' do
      parent_plate.wells[0..39].each { |well| well['state'] = 'passed' }
      expect(subject.number_of_pools).to eq(4)
    end

    #  53 passed, 43 failed
    it 'has 5 pools' do
      parent_plate.wells[0..52].each { |well| well['state'] = 'passed' }
      expect(subject.number_of_pools).to eq(5)
    end

    #  66 passed, 30 failed
    it 'has 6 pools' do
      parent_plate.wells[0..65].each { |well| well['state'] = 'passed' }
      expect(subject.number_of_pools).to eq(6)
    end

    #  77 passed, 19 failed
    it 'has 7 pools' do
      parent_plate.wells[0..76].each { |well| well['state'] = 'passed' }
      expect(subject.number_of_pools).to eq(7)
    end

    #  88 passed, 8 failed
    it 'has 8 pools' do
      parent_plate.wells[0..87].each { |well| well['state'] = 'passed' }
      expect(subject.number_of_pools).to eq(8)
    end
  end

  describe '#get_well_for_plate_location' do
    it 'returns the well for a given plate and location' do
      expect(subject.get_well_for_plate_location(child_plate, 'A1')).to eq child_plate.wells[0]
    end
  end

  describe '#dest_coordinates' do
    it 'returns a list of A1 -> H1' do
      expect(subject.dest_coordinates).to include('A1', 'H1')
      expect(subject.dest_coordinates.count).to eq(8)
    end
  end

  describe '#transfer_hash' do
    context 'when there are 92 passed samples' do
      before { parent_plate.wells[4..95].each { |well| well['state'] = 'passed' } }

      it 'returns an object where passed source well keys map to pool destination well' do
        result = subject.transfer_hash
        expect(result.length).to eq(92)
        expect(result.map { |_k, v| v[:dest_locn] }.uniq).to eq subject.dest_coordinates
      end
    end

    context 'when there are 21 passed samples' do
      before { parent_plate.wells[4..95].each { |well| well['state'] = 'passed' } }

      it 'returns an object where passed source well keys map to pool destination well' do
        parent_plate.wells[4..74].each { |well| well['state'] = 'failed' }
        result = subject.transfer_hash
        expect(result.length).to eq(21)
        expected_dest_coordinates = subject.dest_coordinates[0..1] # [A1, B1] as 21 passed samples has 2 pools
        expect(result.map { |_k, v| v[:dest_locn] }.uniq).to eq expected_dest_coordinates
      end
    end
  end

  describe '#build_pools' do
    before { parent_plate.wells[4..95].each { |well| well['state'] = 'passed' } }

    it 'return a list of length equal to the config number_of_pools' do
      expect(subject.build_pools.length).to eq(8)
    end

    it 'a sample should only be in one pool' do
      result = subject.build_pools
      expect(result.flatten.uniq.count).to eq 92
    end

    context 'returns a nested list with samples allocated to the correct number of pools' do
      it 'returns a list of 8 pools, each with 96 passed samples' do
        parent_plate.wells[0..3].each { |well| well['state'] = 'passed' }
        result_pools = subject.build_pools
        expect(result_pools.each.map(&:count)).to eq([12, 12, 12, 12, 12, 12, 12, 12])
      end

      it 'returns a list of 5 pools, each with 55 passed samples' do
        parent_plate.wells[4..40].each { |well| well['state'] = 'failed' }
        result_pools = subject.build_pools
        expect(result_pools.each.map(&:count)).to eq([11, 11, 11, 11, 11])
      end

      it 'returns a list of 2 pools, each with 21 passed samples' do
        parent_plate.wells[4..74].each { |well| well['state'] = 'failed' }
        result_pools = subject.build_pools
        expect(result_pools.each.map(&:count)).to eq([11, 10])
      end

      it 'returns a a list of 1 pool, with 10 samples' do
        parent_plate.wells[4..85].each { |well| well['state'] = 'failed' }
        result_pools = subject.build_pools
        expect(result_pools.each.map(&:count)).to eq([10])
      end
    end
  end

  describe '#wells_grouped_by_collected_by' do
    before { parent_plate.wells[4..95].each { |well| well['state'] = 'passed' } }

    it "returns what's expected" do
      expect(subject.wells_grouped_by_collected_by.count).to eq(3)
    end

    context 'the wells within a collected_by group are randomised' do
      it "returns what's expected" do
        # Difficult to test randomness as there is a chance this fails if the randomisation is such that it remains the
        # same order
        expect(subject.wells_grouped_by_collected_by['collected by location 2']).not_to eq parent_plate.wells[9..49]
      end
    end

    context 'when there are 4 collection sites, but only 3 collection sites contain passed samples' do
      it "returns what's expected" do
        collected_by_group4 = parent_plate.wells[0..3] # contains only failed samples
        collected_by_group4.each do |well|
          well.aliquots.first.sample.sample_metadata.collected_by = 'collected by location 4'
        end

        expect(subject.wells_grouped_by_collected_by.count).to eq(3)
        expect(subject.wells_grouped_by_collected_by.keys).to contain_exactly(
          'collected by location 3',
          'collected by location 2',
          'collected by location 1'
        )
        expect(subject.wells_grouped_by_collected_by['collected by location 4']).to be_nil
      end
    end
  end
end
