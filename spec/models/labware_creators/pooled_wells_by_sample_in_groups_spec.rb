# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::PooledWellsBySampleInGroups do
  # In these tests, sample uuid and well state are modified at specific
  # wells for setup.

  subject { described_class.new(form_attributes) }

  let(:user_uuid) { 'user-uuid' }
  let(:parent_plate_uuid) { 'parent-plate-uuid' }
  let(:child_plate_uuid) { 'child-plate-uuid' }
  let(:child_purpose_uuid) { 'child-purpose-uuid' }

  # Create a plate with 96 wells in pending state and 1 aliquot in each well
  # and then add requests to the aliquots with the same submission_id.
  let(:parent_plate) do
    plate = create(:v2_plate, uuid: parent_plate_uuid, aliquots_without_requests: 1)
    requests = create_list(:request, 96, submission_id: 2)
    plate.wells.each_with_index { |well, index| well.aliquots.first.request = requests[index] }
    plate
  end

  # Attributes for initialising the labware creator
  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_plate_uuid, user_uuid: user_uuid } }

  # Child plate assumed to be created
  let(:child_plate) { create(:v2_plate, uuid: child_plate_uuid) }

  before do
    # Create a purpose config for the plate (number_of_source_wells is 2)
    create(:pooled_wells_by_sample_in_groups_purpose_config, uuid: child_purpose_uuid)
    allow(subject).to receive(:parent).and_return(parent_plate)
    stub_v2_plate(parent_plate, stub_search: false)
    stub_v2_plate(child_plate, stub_search: false)
  end

  describe '#number_of_source_wells' do
    before do
      # Use a different purpose config for this test (number_of_source_wells is 3)
      create(:pooled_wells_by_sample_in_groups_purpose_config, uuid: child_purpose_uuid, number_of_source_wells: 3)
    end

    it 'returns the number of source wells from the purpose_config' do
      expect(subject.number_of_source_wells).to eq(3)
    end
  end

  describe '#source_plate' do
    it 'returns the source plate' do
      expect(subject.source_plate).to eq(parent_plate)
    end
  end

  describe '#parent_wells_for_pooling' do
    context 'when wells are not ordered inside columns' do
      before do
        # Swap two wells in the column so that they are not in correct order
        parent_plate.wells.map { |well| well.state = 'failed' }
        parent_plate.wells[0].state = 'passed'
        parent_plate.wells[7].state = 'passed'
        parent_plate.wells[0], parent_plate.wells[7] = parent_plate.wells[7], parent_plate.wells[0]
      end

      it 'returns passed source wells in correct order' do
        wells = subject.parent_wells_for_pooling
        expect(wells[0].location).to eq('A1')
        expect(wells[1].location).to eq('H1')
      end
    end

    context 'when wells are not ordered between columns' do
      before do
        # Swap wells between columns so that they are not in correct order
        parent_plate.wells.map { |well| well.state = 'failed' }
        parent_plate.wells[0].state = 'passed'
        parent_plate.wells[8].state = 'passed'
        parent_plate.wells[0], parent_plate.wells[8] = parent_plate.wells[8], parent_plate.wells[0]
      end

      it 'returns passed source wells in correct order' do
        wells = subject.parent_wells_for_pooling
        expect(wells[0].location).to eq('A1')
        expect(wells[1].location).to eq('A2')
      end
    end

    context 'when filtering source wells by state' do
      before do
        parent_plate.wells[0..3].map { |well| well.state = 'failed' }
        parent_plate.wells[4..95].map { |well| well.state = 'passed' }
      end

      it 'ignores source wells that are failed' do
        expect(subject.parent_wells_for_pooling).not_to include(*parent_plate.wells[0..3])
      end

      it 'returns source wells that are passed' do
        expect(subject.parent_wells_for_pooling).to include(*parent_plate.wells[4..95])
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

  describe '#request_hash' do
    let(:source_well) { parent_plate.wells.first }

    before do
      parent_plate.wells.map { |well| well.state = 'failed' }
      source_well.state = 'passed'
    end

    it 'returns request hash' do
      submission_id = source_well.aliquots.first.request.submission_id
      additional_parameters = { submission_id: }
      request = subject.request_hash(source_well, child_plate, additional_parameters)

      # Assume A1 to A1 transfer
      expect(request[:source_asset]).to eq(source_well.uuid)
      expect(request[:target_asset]).to eq(child_plate.wells.first.uuid)
      expect(request[:merge_equivalent_aliquots]).to be(true)
      expect(request[:submission_id]).to eq(submission_id)
    end
  end

  describe '#transfer_request_attributes' do
    context 'when there is no passed source well' do
      before { parent_plate.wells.map { |well| well.state = 'failed' } }

      it 'returns empty list' do
        expect(subject.transfer_request_attributes(child_plate)).to eq([])
      end
    end

    context 'when there are passed source wells' do
      before do
        parent_plate.wells.map { |well| well.state = 'failed' }
        parent_plate.wells[0..3].map { |well| well.state = 'passed' }
        samples = %w[sample_1_uuid sample_1_uuid sample_1_uuid sample_2_uuid]
        samples.each_with_index do |sample_uuid, index|
          parent_plate.wells[index].aliquots.first.sample.uuid = sample_uuid
        end
      end

      it 'returns list of transfer request attributes' do
        requests = subject.transfer_request_attributes(child_plate)
        expect(requests.size).to eq(4)

        # Source wells: A1, B1, C1, D1
        requests.each_with_index do |request, index|
          expect(request[:source_asset]).to eq(parent_plate.wells[index].uuid)
          expect(request[:merge_equivalent_aliquots]).to be(true)
        end

        # Destination wells: A1, A1, B1, C1
        child_uuids = child_plate.wells.values_at(0, 0, 1, 2).map(&:uuid)
        requests.each_with_index do |request, index|
          target_uuid = child_uuids[index]
          expect(request[:target_asset]).to eq(target_uuid)
        end
      end
    end
  end

  describe '#transfer_material_from_parent!' do
    let(:transfer_requests_attributes) { subject.transfer_request_attributes(child_plate) }

    before do
      parent_plate.wells.map { |well| well.state = 'failed' }
      parent_plate.wells[0..2].map { |well| well.state = 'passed' }
      parent_plate.wells[0].aliquots.first.sample.uuid = 'sample_1_uuid'
      parent_plate.wells[1].aliquots.first.sample.uuid = 'sample_1_uuid'
      parent_plate.wells[2].aliquots.first.sample.uuid = 'sample_2_uuid'
    end

    it 'posts transfer requests to SS' do
      expect_transfer_request_collection_creation

      subject.transfer_material_from_parent!(child_plate.uuid)
    end
  end
end
