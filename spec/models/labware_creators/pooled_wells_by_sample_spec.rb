# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::PooledWellsBySample do
  has_a_working_api

  let(:user_uuid) { 'user-uuid' }
  let(:parent_plate_uuid) { 'parent-plate-uuid' }
  let(:child_purpose_uuid) { 'child-purpose-uuid' }
  let(:parent_plate) { create(:v2_plate, uuid: parent_plate_uuid, aliquots_without_requests: 1) }
  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_plate_uuid, user_uuid: user_uuid } }
  subject { described_class.new(api, form_attributes) }
  before do
    allow(subject).to receive(:parent).and_return(parent_plate)
    stub_v2_plate(parent_plate, stub_search: false)
  end

  describe '#number_of_source_wells' do
    context 'when purpose_config includes number_of_source_wells' do
      before { create(:purpose_config, uuid: child_purpose_uuid, number_of_source_wells: 3) }

      it 'returns the number of source wells from the purpose_config' do
        expect(subject.number_of_source_wells).to eq(3)
      end
    end

    context 'when purpose_config does not include number_of_source_wells' do
      before { create(:purpose_config, uuid: child_purpose_uuid) }
      it 'returns the default number of source wells' do
        expect(subject.number_of_source_wells).to eq(2)
      end
    end
  end

  describe '#source_plate' do
    it 'returns the source plate' do
      expect(subject.source_plate).to eq(parent_plate)
    end
  end

  describe '#passed_parent_wells' do
    before do
      parent_plate.wells[0..3].map { |well| well.state = 'failed' }
      parent_plate.wells[4..95].map { |well| well.state = 'passed' }
    end

    it 'ignores source wells that have been failed' do
      expect(subject.passed_parent_wells).not_to include(*parent_plate.wells[0..3])
    end

    it 'returns source wells that have been passed' do
      expect(subject.passed_parent_wells).to include(*parent_plate.wells[4..95])
    end
  end

  describe '#parent_wells_in_columns' do
    context 'inside columns' do
      before do
        # Swap two wells in the column so that they are not in correct order
        parent_plate.wells.map { |well| well.state = 'failed' }
        parent_plate.wells[0].state = 'passed'
        parent_plate.wells[7].state = 'passed'
        parent_plate.wells[0], parent_plate.wells[7] = parent_plate.wells[7], parent_plate.wells[0]
      end

      it 'returns passed source wells in correct order' do
        wells = subject.parent_wells_in_columns
        expect(wells[0].location).to eq('A1')
        expect(wells[1].location).to eq('H1')
      end
    end
    context 'between columns' do
      before do
        # Swap wells between columns so that they are not in correct order
        parent_plate.wells.map { |well| well.state = 'failed' }
        parent_plate.wells[0].state = 'passed'
        parent_plate.wells[8].state = 'passed'
        parent_plate.wells[0], parent_plate.wells[8] = parent_plate.wells[8], parent_plate.wells[0]
      end
      it 'returns passed source wells in correct order' do
        wells = subject.parent_wells_in_columns
        expect(wells[0].location).to eq('A1')
        expect(wells[1].location).to eq('A2')
      end
    end
  end

  describe '#build_pools' do
    let(:sample_uuids) do
      # If well E1 with sample_3_uuid is failed and number_of_source_wells is 2, pools will be:
      # ["A1", "B1"]
      # ["C1"]
      # ["D1"]
      # ["F1", "G1"]
      # ["H1", "A2"]
      %w[
        sample_1_uuid
        sample_1_uuid
        sample_1_uuid
        sample_2_uuid
        sample_3_uuid
        sample_4_uuid
        sample_4_uuid
        sample_5_uuid
        sample_5_uuid
      ]
    end
    before do
      parent_plate.wells[0..(sample_uuids.size - 1)].each_with_index do |well, index|
        well.aliquots.first.sample.uuid = sample_uuids[index]
        well.state = 'passed'
      end
      parent_plate.wells[4].state = 'failed' # fail well E1 with sample_3_uuid
    end

    it 'builds correct number of pools' do
      expect(subject.build_pools.size).to eq(5)
    end

    it 'builds up to the number of source wells' do
      pools = subject.build_pools
      expect(pools[0].size).to eq(2)
      expect(pools[0][0].location).to eq('A1')
      expect(pools[0][0].aliquots.first.sample.uuid).to eq('sample_1_uuid')
      expect(pools[0][1].location).to eq('B1')
      expect(pools[0][1].aliquots.first.sample.uuid).to eq('sample_1_uuid')
    end

    it 'builds with remaining source wells' do
      pools = subject.build_pools
      expect(pools[1].size).to eq(1)
      expect(pools[1][0].location).to eq('C1')
      expect(pools[1][0].aliquots.first.sample.uuid).to eq('sample_1_uuid') # third well with sample_1_uuid
    end

    it 'builds with one source well' do
      pools = subject.build_pools
      expect(pools[2].size).to eq(1)
      expect(pools[2][0].location).to eq('D1')
      expect(pools[2][0].aliquots.first.sample.uuid).to eq('sample_2_uuid') # only well with sample_2_uuid
    end

    it 'builds without failed source wells' do
      locations = subject.build_pools.flatten(1).map(&:location)
      expect(locations).not_to include('E1')
    end

    it 'builds in column order' do
      pools = subject.build_pools
      expect(pools[4].size).to eq(2)
      expect(pools[4][1].location).to eq('A2')
      expect(pools[4][1].aliquots.first.sample.uuid).to eq('sample_5_uuid')
    end
  end

  describe '#transfer_hash' do
    before do
      parent_plate.wells.map { |well| well.state = 'failed' }
      parent_plate.wells[0..2].map { |well| well.state = 'passed' }
      parent_plate.wells[0].aliquots.first.sample.uuid = 'sample_1_uuid'
      parent_plate.wells[1].aliquots.first.sample.uuid = 'sample_1_uuid'
      parent_plate.wells[2].aliquots.first.sample.uuid = 'sample_2_uuid'
    end

    it 'returns a mapping of source wells to destination wells' do
      result = subject.transfer_hash
      expect(result.size).to eq(3)
      expect(result['A1']).to eq(dest_locn: 'A1')
      expect(result['B1']).to eq(dest_locn: 'A1')
      expect(result['C1']).to eq(dest_locn: 'B1')
    end
  end

  describe '#get_well_for_plate_location' do
    it 'returns well for well location on plate' do
      well = subject.get_well_for_plate_location(parent_plate, 'A1')
      expect(well.location).to eq('A1')
    end
  end
end
