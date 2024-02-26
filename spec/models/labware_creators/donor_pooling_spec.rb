# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::DonorPoolingPlate do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has a custom page', 'donor_pooling_plate'

  has_a_working_api

  subject { described_class.new(api, form_attributes) }
  let(:parent_1_plate_uuid) { 'parent-1-plate-uuid' }
  let(:parent_2_plate_uuid) { 'parent-2-plate-uuid' }
  let(:parent_purpose_uuid) { 'parent-purpose-uuid' }
  let(:child_purpose_uuid) { 'child-purpose-uuid' }
  let(:requests) { create_list(:request, 96, submission_id: 1) }

  let(:parent_1_plate) do
    plate = create(:v2_plate, uuid: parent_1_plate_uuid, aliquots_without_requests: 1)
    plate.wells.each_with_index { |well, index| well.aliquots.first.request = requests[index] }
    plate
  end

  let(:parent_2_plate) do
    plate = create(:v2_plate, uuid: parent_1_plate_uuid, aliquots_without_requests: 1)
    plate.wells.each_with_index { |well, index| well.aliquots.first.request = requests[index] }
    plate
  end

  let(:study_1) { create(:v2_study, name: 'study-1-name') }
  let(:study_2) { create(:v2_study, name: 'study-2-name') }
  let(:study_3) { create(:v2_study, name: 'study-3-name') }

  let(:project_1) { create(:v2_project, name: 'project-1-name') }
  let(:project_2) { create(:v2_project, name: 'project-2-name') }
  let(:project_3) { create(:v2_project, name: 'project-3-name') }

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_1_plate_uuid, barcodes: barcodes } }
  let(:source_plates) { [parent_1_plate, parent_2_plate] }
  let(:barcodes) { source_plates.map { |plate| plate.barcode.human } }

  before do
    create(:donor_pooling_plate_purpose_config, uuid: child_purpose_uuid)
    allow(Sequencescape::Api::V2::Plate).to receive(:find_all)
      .with({ barcode: barcodes }, includes: described_class::SOURCE_PLATE_INCLUDES)
      .and_return(source_plates)
  end

  describe '.attributes' do
    it 'includes barcodes' do
      expect(described_class.attributes).to include(a_hash_including(barcodes: []))
    end
  end

  describe '#number_of_source_plates' do
    it 'returns the number of source plates' do
      expect(subject.number_of_source_plates).to eq(2)
    end

    context 'with a different number of source plates' do
      before { create(:donor_pooling_plate_purpose_config, uuid: child_purpose_uuid, number_of_source_plates: 3) }

      it 'returns the number of source plates' do
        expect(subject.number_of_source_plates).to eq(3)
      end
    end
  end

  describe '#well_filter' do
    it 'returns a WellFilter with the creator set to self' do
      well_filter = subject.well_filter
      expect(well_filter).to be_a(LabwareCreators::WellFilter)
      expect(well_filter.creator).to eq(subject)
    end

    it 'returns the same instance' do
      expect(subject.well_filter).to be(subject.well_filter)
    end
  end

  describe '#labware_wells' do
    it 'returns the passed wells from the source plates' do
      parent_1_plate.wells[0].state = 'passed'
      parent_2_plate.wells[0].state = 'passed'
      expect(subject.labware_wells).to eq([parent_1_plate.wells[0], parent_2_plate.wells[0]])
    end
  end

  describe '#source_plates' do
    it 'returns the source plates' do
      subject.barcodes = barcodes
      expect(subject.source_plates).to eq([parent_1_plate, parent_2_plate])
    end
  end

  describe '#source_wells_for_pooling' do
    it 'returns the filtered wells from the source plates' do
      parent_1_plate.wells[0].state = 'passed'
      parent_2_plate.wells[0].state = 'passed'
      expect(subject.source_wells_for_pooling).to eq([parent_1_plate.wells[0], parent_2_plate.wells[0]])
    end
  end

  describe '#barcodes=' do
    it 'sets the barcodes' do
      expect(subject.barcodes).to eq(barcodes)
      expect(subject.minimal_barcodes).to eq(barcodes)
    end

    it 'cleans the barcodes' do
      new_barcodes = barcodes.map { |barcode| "\r\n\t\v\f #{barcode} \r\n\t\v\f" } + ['', " \r\n\t\v\f ", nil]
      subject.barcodes = new_barcodes
      expect(subject.barcodes).to eq(new_barcodes)
      expect(subject.minimal_barcodes).to eq(barcodes)
    end
  end

  describe '#number_of_pools' do
    # TODO: Change this test once a new CSV file is provided.
    context 'when number of samples is less than or equal to 96' do
      it 'returns the number of pools from lookup table' do
        {
          1 => 1,
          21 => 2,
          27 => 3,
          40 => 4,
          53 => 5,
          66 => 6,
          77 => 7,
          88 => 8,
          96 => 8
        }.each do |number_of_samples, number_of_pools|
          parent_1_plate.wells[0..(number_of_samples - 1)].each { |well| well.state = 'passed' }
          subject.well_filter.instance_variable_set(:@well_transfers, nil) # reset well_filter cache
          expect(subject.number_of_pools).to eq(number_of_pools)
        end
      end
    end

    context 'when number of samples is greater than 96' do
      it 'returns the number of pools from constant' do
        parent_1_plate.wells[0..96].each { |well| well.state = 'passed' }
        {
          97 => described_class::DEFAULT_NUMBER_OF_POOLS,
          160 => described_class::DEFAULT_NUMBER_OF_POOLS
        }.each do |number_of_samples, number_of_pools|
          parent_2_plate.wells[0..(number_of_samples - 97)].each { |well| well.state = 'passed' }
          subject.well_filter.instance_variable_set(:@well_transfers, nil) # reset well_filter cache
          expect(subject.number_of_pools).to eq(number_of_pools)
        end
      end
    end
  end

  describe '#split_single_group_by_study_and_project' do
    it 'returns the grouped wells' do
      well_p1_w1 = well = parent_1_plate.wells[0]
      well.state = 'passed'
      well.aliquots.first.study = study_1
      well.aliquots.first.project = project_1

      well_p1_w2 = well = parent_1_plate.wells[1]
      well.state = 'passed'
      well.aliquots.first.study = study_1
      well.aliquots.first.project = project_1

      well_p1_w3 = well = parent_1_plate.wells[2]
      well.state = 'passed'
      well.aliquots.first.study = study_2
      well.aliquots.first.project = project_1

      well_p1_w4 = well = parent_1_plate.wells[3]
      well.state = 'passed'
      well.aliquots.first.study = study_2
      well.aliquots.first.project = project_2

      well_p2_w1 = well = parent_2_plate.wells[0]
      well.state = 'passed'
      well.aliquots.first.study = study_1
      well.aliquots.first.project = project_1

      well_p2_w2 = well = parent_2_plate.wells[1]
      well.state = 'passed'
      well.aliquots.first.study = study_2
      well.aliquots.first.project = project_2

      groups = [
        [well_p1_w1, well_p1_w2, well_p2_w1], # study_1, project_1
        [well_p1_w3], # study_2, project_1
        [well_p1_w4, well_p2_w2] # study_2, project_2
      ]
      expect(subject.split_single_group_by_study_and_project(groups.flatten)).to eq(groups)
    end
  end

  describe '#split_single_group_by_unique_donor_ids' do
    it 'returns the split groups' do
      well_p1_w1 = well = parent_1_plate.wells[0]
      well.state = 'passed'
      well.aliquots.first.sample.sample_metadata.donor_id = 1

      well_p1_w2 = well = parent_1_plate.wells[1]
      well.state = 'passed'
      well.aliquots.first.sample.sample_metadata.donor_id = 1

      well_p1_w3 = well = parent_1_plate.wells[2]
      well.state = 'passed'
      well.aliquots.first.sample.sample_metadata.donor_id = 2

      well_p2_w1 = well = parent_2_plate.wells[0]
      well.state = 'passed'
      well.aliquots.first.sample.sample_metadata.donor_id = 1

      well_p2_w2 = well = parent_2_plate.wells[1]
      well.state = 'passed'
      well.aliquots.first.sample.sample_metadata.donor_id = 2

      well_p2_w3 = well = parent_2_plate.wells[2]
      well.state = 'passed'
      well.aliquots.first.sample.sample_metadata.donor_id = 3

      group = [well_p1_w1, well_p1_w2, well_p1_w3, well_p2_w1, well_p2_w2, well_p2_w3]
      split_groups = [
        [well_p1_w1, well_p1_w3, well_p2_w3], # donor_id 1, 2, 3
        [well_p1_w2, well_p2_w2], # donor_id 1, 2
        [well_p2_w1] # donor_id 1
      ]
      expect(subject.split_single_group_by_unique_donor_ids(group)).to match_array(split_groups)
    end
  end

  describe '#unique_donor_ids' do
    it 'returns the unique donor ids' do
      well_p1_w1 = well = parent_1_plate.wells[0]
      well.aliquots.first.sample.sample_metadata.donor_id = 1

      well_p1_w2 = well = parent_1_plate.wells[1]
      well.aliquots.first.sample.sample_metadata.donor_id = 1

      well_p1_w3 = well = parent_1_plate.wells[2]
      well.aliquots.first.sample.sample_metadata.donor_id = 2

      well_p2_w1 = well = parent_2_plate.wells[0]
      well.aliquots.first.sample.sample_metadata.donor_id = 1

      well_p2_w2 = well = parent_2_plate.wells[1]
      well.aliquots.first.sample.sample_metadata.donor_id = 2

      well_p2_w3 = well = parent_2_plate.wells[2]
      well.aliquots.first.sample.sample_metadata.donor_id = 3

      group = [well_p1_w1, well_p1_w2, well_p1_w3, well_p2_w1, well_p2_w2, well_p2_w3]
      unique_donor_ids = [1, 2, 3]
      expect(subject.unique_donor_ids(group)).to eq(unique_donor_ids)
    end
  end

  describe '#distribute_groups_across_pools' do
    context 'with well groups' do
      it 'divides large groups' do
        groups = [
          parent_1_plate.wells[1..9], # 9 wells
          parent_1_plate.wells[10..15], # 6 wells
          parent_2_plate.wells[16..20], # 5 wells
          parent_2_plate.wells[21..21] # 1 well
        ]

        # Helper method (g) to write the expected result.
        wells = groups.flatten
        g = proc { |*numbers| numbers.map { |number| wells[number - 1] } }

        distributed_groups = [
          g[21],
          g[10, 11, 12],
          g[13, 14, 15],
          g[6, 7, 8, 9],
          g[16, 17, 18, 19, 20],
          g[1, 2, 3, 4, 5]
        ]
        expect(subject.distribute_groups_across_pools(groups, 6)).to match_array(distributed_groups)
      end
    end

    context 'when the number of groups is less than the number of pools' do
      it 'divides large groups' do
        # Using integers for easy reading.
        groups = [[1, 2, 3, 4, 5, 6, 7, 8, 9], [10, 11, 12, 13, 14, 15], [16, 17, 18, 19, 20], [21]]
        distributed_groups = [[21], [10, 11, 12], [13, 14, 15], [6, 7, 8, 9], [16, 17, 18, 19, 20], [1, 2, 3, 4, 5]]
        expect(subject.distribute_groups_across_pools(groups, 6)).to match_array(distributed_groups)
      end
    end

    context 'when the number of groups is equal to the number of pools' do
      it 'returns the groups intact' do
        # Using integers for easy reading.
        groups = [[1, 2, 3, 4, 5, 6, 7, 8, 9], [10, 11, 12, 13, 14, 15], [16, 17, 18, 19, 20], [21]]
        expect(subject.distribute_groups_across_pools(groups, 4)).to match_array(groups)
      end
    end

    context 'when the number of groups is greater than the number of pools' do
      it 'returns the groups intact' do
        # Using integers for easy reading.
        groups = [[1, 2, 3, 4, 5, 6, 7, 8, 9], [10, 11, 12, 13, 14, 15], [16, 17, 18, 19, 20], [21]]
        expect(subject.distribute_groups_across_pools(groups, 4)).to match_array(groups)
      end
    end

    context 'when the number of pools is too large' do
      it 'divides all groups' do
        # Using integers for easy reading.
        groups = [[1, 2, 3, 4, 5, 6, 7, 8, 9], [10, 11, 12, 13, 14, 15], [16, 17, 18, 19, 20], [21]]
        distributed_groups = (1..21).map { |n| [n] }
        expect(subject.distribute_groups_across_pools(groups, 25)).to match_array(distributed_groups)
      end
    end
  end

  describe '#build_pools' do
    let(:studies) { create_list(:v2_study, 16) }
    let(:projects) { create_list(:v2_project, 16) }
    let(:donor_ids) { (1..160).to_a }
    let(:wells) { parent_1_plate.wells + parent_2_plate.wells[0..63] }

    before do
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = studies[index % 16]
        well.aliquots.first.project = projects[index % 16]
        well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
      end
    end

    it 'returns correct number of pools' do
      pools = subject.build_pools
      expect(pools.size).to eq(described_class::DEFAULT_NUMBER_OF_POOLS)
      expect(pools.flatten).to match_array(wells)
    end

    it 'returns correct number of studies in each pool' do
      pools = subject.build_pools
      pools.each do |pool|
        number_of_unique_study_ids = pool.map { |well| well.aliquots.first.study.id }.uniq.size
        expect(number_of_unique_study_ids).to eq(1)
      end
    end

    it 'returns correct number of projects in each pool' do
      pools = subject.build_pools
      pools.each do |pool|
        number_of_unique_project_ids = pool.map { |well| well.aliquots.first.project.id }.uniq.size
        expect(number_of_unique_project_ids).to eq(1)
      end
    end

    it 'returns correct number of donors in each pool' do
      # Even distribution of donors across pools.
      pools = subject.build_pools
      pools.each do |pool|
        number_of_unique_donor_ids = pool.map { |well| well.aliquots.first.sample.sample_metadata.donor_id }.uniq.size
        expect(number_of_unique_donor_ids).to eq(wells.size / described_class::DEFAULT_NUMBER_OF_POOLS)
      end
    end
  end
end
