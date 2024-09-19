# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::DonorPoolingPlate do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has a custom page', 'donor_pooling_plate'

  has_a_working_api

  subject { described_class.new(api, form_attributes) }
  let(:user_uuid) { 'user-uuid' }
  let(:parent_1_plate_uuid) { 'parent-1-plate-uuid' }
  let(:parent_2_plate_uuid) { 'parent-2-plate-uuid' }
  let(:parent_purpose_uuid) { 'parent-purpose-uuid' }
  let(:child_purpose_uuid) { 'child-purpose-uuid' }
  let(:child_plate_uuid) { 'child-plate-uuid' }
  let(:num_samples_per_pool) { 16 }
  let(:requests) do
    create_list(
      :scrna_customer_request,
      192,
      submission_id: 1,
      request_metadata: create(:v2_request_metadata, number_of_samples_per_pool: num_samples_per_pool)
    )
  end

  let(:parent_1_plate) do
    # The aliquots_without_requests parameter is to prevent the default
    # request creation so we can use the same submission_id on requests.
    plate = create(:v2_plate, uuid: parent_1_plate_uuid, aliquots_without_requests: 1)
    plate.wells.each_with_index do |well, index|
      well.aliquots.first.request = requests[index]
      well.aliquots.first.sample.sample_metadata.donor_id = nil
    end
    plate
  end

  let(:parent_2_plate) do
    # The aliquots_without_requests parameter is to prevent the default
    # request creation so we can use the same submission_id on requests.
    plate = create(:v2_plate, uuid: parent_2_plate_uuid, aliquots_without_requests: 1)
    plate.wells.each_with_index do |well, index|
      well.aliquots.first.request = requests[96 + index]
      well.aliquots.first.sample.sample_metadata.donor_id = nil
    end
    plate
  end
  let(:source_plates) { [parent_1_plate, parent_2_plate] }

  let(:child_plate) { create(:v2_plate, uuid: child_plate_uuid) }

  # Usually we need three studies for testing.
  let(:study_1) { create(:v2_study, name: 'study-1-name') }
  let(:study_2) { create(:v2_study, name: 'study-2-name') }
  let(:study_3) { create(:v2_study, name: 'study-3-name') }

  # Usually we need three projects for testing.
  let(:project_1) { create(:v2_project, name: 'project-1-name') }
  let(:project_2) { create(:v2_project, name: 'project-2-name') }
  let(:project_3) { create(:v2_project, name: 'project-3-name') }

  # This is the form that includes plate barcodes, submitted by user.
  let(:form_attributes) do
    { purpose_uuid: child_purpose_uuid, parent_uuid: parent_1_plate_uuid, barcodes: barcodes, user_uuid: user_uuid }
  end
  let(:barcodes) { source_plates.map(&:human_barcode) }

  let(:default_number_of_pools) { 16 }

  before do
    # Create the pooling config and add to Settings.
    create(:donor_pooling_config)

    # Create the plate purpose config and add to Settings.
    create(
      :donor_pooling_plate_purpose_config,
      uuid: child_purpose_uuid,
      default_number_of_pools: default_number_of_pools
    )

    # Allow the API call to return two plates by default.
    allow(Sequencescape::Api::V2::Plate).to receive(:find_all)
      .with({ barcode: barcodes }, includes: described_class::SOURCE_PLATE_INCLUDES)
      .and_return(source_plates)
  end

  describe '.attributes' do
    it 'includes barcodes' do
      expect(described_class.attributes).to include(a_hash_including(barcodes: []))
    end
  end

  describe '#max_number_of_source_plates' do
    it 'returns the number of source plates' do
      expect(subject.max_number_of_source_plates).to eq(2)
    end

    context 'with a different number of source plates' do
      before { create(:donor_pooling_plate_purpose_config, uuid: child_purpose_uuid, max_number_of_source_plates: 3) }

      it 'returns the number of source plates' do
        expect(subject.max_number_of_source_plates).to eq(3)
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

  describe '#source_wells_to_plates' do
    it 'returns a hash mapping source wells to their plates' do
      hash = subject.source_wells_to_plates
      expect(hash[parent_1_plate.wells.first]).to eq(parent_1_plate)
      expect(hash[parent_1_plate.wells.last]).to eq(parent_1_plate)
      expect(hash[parent_2_plate.wells.first]).to eq(parent_2_plate)
      expect(hash[parent_2_plate.wells.last]).to eq(parent_2_plate)
      expect(hash.size).to eq(parent_1_plate.wells.size + parent_2_plate.wells.size)
    end

    it 'caches the result' do
      expect(subject.source_wells_to_plates).to be(subject.source_wells_to_plates) # same instance
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
    let(:source_well) { double('SourceWell') }
    let(:aliquot) { double('Aliquot') }
    let(:request) { double('Request') }
    let(:request_metadata) { double('RequestMetadata') }

    before do
      allow(subject).to receive(:source_wells_for_pooling).and_return([source_well])
      allow(source_well).to receive(:aliquots).and_return([aliquot])
      allow(aliquot).to receive(:request).and_return(request)
      allow(request).to receive(:request_metadata).and_return(request_metadata)
    end

    context 'when all dependencies are present' do
      it 'returns the number of samples per pool' do
        allow(request_metadata).to receive(:number_of_samples_per_pool).and_return(5)
        expect(subject.fetch_number_of_samples_per_pool_from_request).to eq(5)
      end
    end

    context 'when request_metadata.number_of_samples_per_pool is nil' do
      it 'raises an error' do
        allow(request_metadata).to receive(:number_of_samples_per_pool).and_return(nil)
        expect { subject.fetch_number_of_samples_per_pool_from_request }.to raise_error(
          StandardError,
          'Error: request_metadata.number_of_samples_per_pool is nil'
        )
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
      well.aliquots.first.sample.sample_metadata.donor_id = 1 # Using integer donor_ids for easy setup.

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
      well.aliquots.first.sample.sample_metadata.donor_id = 1 # Using integer donor_ids for easy setup.

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

  describe '#pools' do
    let!(:wells) do # eager!
      wells = [parent_1_plate.wells[0], parent_1_plate.wells[1], parent_2_plate.wells[0]]
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
      end
    end

    it 'builds the pools' do
      pools = subject.pools
      expect(pools.size).to eq(1)
      expect(pools[0]).to match_array(wells)
    end

    it 'caches the result' do
      expect(subject.pools).to be(subject.pools) # same instance
    end
  end

  describe '#build_pools' do
    context 'when standard behaviour' do
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
        expect(pools.size).to eq(default_number_of_pools)
        expect(pools.flatten).to match_array(wells)
      end

      it 'returns pools with correct number of studies' do
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_study_ids = pool.map { |well| well.aliquots.first.study.id }.uniq.size
          expect(number_of_unique_study_ids).to eq(1)
        end
      end

      it 'returns pools with correct number of projects' do
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_project_ids = pool.map { |well| well.aliquots.first.project.id }.uniq.size
          expect(number_of_unique_project_ids).to eq(1)
        end
      end

      it 'returns pools with correct number of donors' do
        # Even distribution of donors across pools.
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_donor_ids = pool.map { |well| well.aliquots.first.sample.sample_metadata.donor_id }.uniq.size
          expect(number_of_unique_donor_ids).to eq(wells.size / default_number_of_pools)
        end
      end
    end

    # Checks for behaviour for test runs
    context 'when test run for 10 samples per pool and 8 pools' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:donor_ids) { (1..80).to_a }
      let(:wells) { parent_1_plate.wells[0..79] }
      let(:expected_number_of_pools) { 8 }
      let(:num_samples_per_pool) { 10 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request = requests[index]
          well.aliquots.first.request.request_metadata.number_of_samples_per_pool = num_samples_per_pool
        end
      end

      it 'returns correct number of pools' do
        pools = subject.build_pools
        expect(pools.size).to eq(expected_number_of_pools)
        expect(pools.flatten).to match_array(wells)
      end

      it 'returns pools with correct number of studies' do
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_study_ids = pool.map { |well| well.aliquots.first.study.id }.uniq.size
          expect(number_of_unique_study_ids).to eq(1)
        end
      end

      it 'returns pools with correct number of projects' do
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_project_ids = pool.map { |well| well.aliquots.first.project.id }.uniq.size
          expect(number_of_unique_project_ids).to eq(1)
        end
      end

      it 'returns pools with correct number of donors' do
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_donor_ids = pool.map { |well| well.aliquots.first.sample.sample_metadata.donor_id }.uniq.size
          expect(number_of_unique_donor_ids).to eq(pool.size)
        end
      end
    end

    context 'when test run for 24 samples per pool and 8 pools' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:donor_ids) { (1..192).to_a }
      let(:wells) { parent_1_plate.wells + parent_2_plate.wells }
      let(:expected_number_of_pools) { 8 }
      let(:num_samples_per_pool) { 24 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request = requests[index]
          well.aliquots.first.request.request_metadata.number_of_samples_per_pool = num_samples_per_pool
        end
      end

      it 'returns correct number of pools' do
        pools = subject.build_pools
        expect(pools.size).to eq(expected_number_of_pools)
        expect(pools.flatten).to match_array(wells)
      end

      it 'returns pools with correct number of studies' do
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_study_ids = pool.map { |well| well.aliquots.first.study.id }.uniq.size
          expect(number_of_unique_study_ids).to eq(1)
        end
      end

      it 'returns pools with correct number of projects' do
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_project_ids = pool.map { |well| well.aliquots.first.project.id }.uniq.size
          expect(number_of_unique_project_ids).to eq(1)
        end
      end

      it 'returns pools with correct number of donors' do
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_donor_ids = pool.map { |well| well.aliquots.first.sample.sample_metadata.donor_id }.uniq.size
          expect(number_of_unique_donor_ids).to eq(pool.size)
        end
      end
    end
  end

  describe '#transfer_request_attributes' do
    let!(:wells) do # eager!
      wells = [parent_1_plate.wells[0], parent_2_plate.wells[0]]
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
      end
    end

    it 'returns the transfer request attributes into destination plate' do
      attributes = subject.transfer_request_attributes(child_plate)
      expect(attributes.size).to eq(2)

      expect(attributes[0]['source_asset']).to eq(wells[0].uuid)
      expect(attributes[0]['target_asset']).to eq(child_plate.wells[0].uuid)
      expect(attributes[0][:aliquot_attributes]).to eq({ 'tag_depth' => '1' })
      expect(attributes[0]['submission_id']).to eq('1') # request factory insists on string

      expect(attributes[1]['source_asset']).to eq(wells[1].uuid)
      expect(attributes[1]['target_asset']).to eq(child_plate.wells[0].uuid)
      expect(attributes[1][:aliquot_attributes]).to eq({ 'tag_depth' => '2' })
      expect(attributes[1]['submission_id']).to eq('1') # request factory insists on string
    end
  end

  describe '#request_hash' do
    let(:wells) do
      wells = [parent_1_plate.wells[0], parent_2_plate.wells[0]]
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
      end
    end

    it 'returns the request hash' do
      hash = subject.request_hash(wells[0], child_plate, { 'submission_id' => '1' })
      expect(hash['source_asset']).to eq(wells[0].uuid)
      expect(hash['target_asset']).to eq(child_plate.wells[0].uuid)
      expect(hash[:aliquot_attributes]).to eq({ 'tag_depth' => '1' })
      expect(hash['submission_id']).to eq('1')

      hash = subject.request_hash(wells[1], child_plate, { 'submission_id' => '1' })
      expect(hash['source_asset']).to eq(wells[1].uuid)
      expect(hash['target_asset']).to eq(child_plate.wells[0].uuid)
      expect(hash[:aliquot_attributes]).to eq({ 'tag_depth' => '2' })
      expect(hash['submission_id']).to eq('1')
    end
  end

  describe '#transfer_hash' do
    let!(:wells) do
      wells = [parent_1_plate.wells[0], parent_1_plate.wells[1], parent_2_plate.wells[0]]
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
        well.aliquots.first.request = requests[index]
        well.aliquots.first.request.request_metadata.number_of_samples_per_pool = num_samples_per_pool
      end
    end

    it 'returns the transfer hash' do
      hash = wells[0..2].index_with { |_well| { dest_locn: 'A1' } }
      expect(subject.transfer_hash).to eq(hash)
    end

    it 'caches the result' do
      expect(subject.transfer_hash).to be(subject.transfer_hash) # same instance
    end
  end

  describe '#tag_depth_hash' do
    it 'returns a hash mapping positions of wells in their pools' do
      well_p1_w1 = well = parent_1_plate.wells[0]
      well.state = 'passed'
      well.aliquots.first.study = study_1
      well.aliquots.first.project = project_1
      well.aliquots.first.sample.sample_metadata.donor_id = 1

      well_p1_w2 = well = parent_1_plate.wells[1]
      well.state = 'passed'
      well.aliquots.first.study = study_1
      well.aliquots.first.project = project_1
      well.aliquots.first.sample.sample_metadata.donor_id = 2

      well_p2_w1 = well = parent_2_plate.wells[0]
      well.state = 'passed'
      well.aliquots.first.study = study_1
      well.aliquots.first.project = project_1
      well.aliquots.first.sample.sample_metadata.donor_id = 3

      well_p2_w2 = well = parent_2_plate.wells[1]
      well.state = 'passed'
      well.aliquots.first.study = study_1
      well.aliquots.first.project = project_1
      well.aliquots.first.sample.sample_metadata.donor_id = 1 # same donor as well_p1_w1

      subject.build_pools
      expect(subject.tag_depth_hash[well_p1_w1]).to eq('1')
      expect(subject.tag_depth_hash[well_p1_w2]).to eq('2')
      expect(subject.tag_depth_hash[well_p2_w1]).to eq('3')
      expect(subject.tag_depth_hash[well_p2_w2]).to eq('1')
    end

    it 'caches the result' do
      well = parent_1_plate.wells[0]
      well.state = 'passed'
      well.aliquots.first.study = study_1
      well.aliquots.first.project = project_1
      well.aliquots.first.sample.sample_metadata.donor_id = 1

      subject.build_pools
      expect(subject.tag_depth_hash).to be(subject.tag_depth_hash) # same instance
    end
  end

  describe '#transfer_material_from_parent!' do
    let!(:wells) do # eager!
      wells = [parent_1_plate.wells[0], parent_2_plate.wells[0]]
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
      end
    end

    let!(:stub_transfer_material_request) do # eager!
      allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(uuid: child_plate.uuid).and_return(child_plate)
      stub_api_post(
        'transfer_request_collections',
        payload: {
          transfer_request_collection: {
            user: user_uuid,
            transfer_requests: subject.transfer_request_attributes(child_plate)
          }
        },
        body: '{}'
      )
    end
    it 'posts transfer requests to Sequencescape' do
      subject.transfer_material_from_parent!(child_plate.uuid)
      expect(stub_transfer_material_request).to have_been_made
    end
  end

  describe '#valid?' do
    describe '#source_barcodes_must_be_entered' do
      let(:barcodes) { [] }
      it 'reports the error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:source_barcodes]).to include(described_class::SOURCE_BARCODES_MUST_BE_ENTERED)
      end
    end

    describe '#source_barcodes_must_be_different' do
      before do
        allow(Sequencescape::Api::V2::Plate).to receive(:find_all)
          .with({ barcode: barcodes }, includes: described_class::SOURCE_PLATE_INCLUDES)
          .and_return([parent_1_plate])
      end
      let(:barcodes) { [parent_1_plate.human_barcode] * 2 }
      it 'reports the error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:source_barcodes]).to include(described_class::SOURCE_BARCODES_MUST_BE_DIFFERENT)
      end

      context 'with single barcode' do
        let!(:wells) do
          well = parent_1_plate.wells[0]
          well.state = 'passed'
          well.aliquots.first.study = study_1
          well.aliquots.first.project = project_1
          well.aliquots.first.sample.sample_metadata.donor_id = 1
          well.aliquots.first.request = requests[0]
          well.aliquots.first.request.request_metadata.number_of_samples_per_pool = num_samples_per_pool

          # TODO: are we changing this to total cell count?
          well.qc_results << create(:qc_result, key: 'live_cell_count', units: 'cells/ml', value: 1_000_000)
          [well]
        end
        before do
          allow(Sequencescape::Api::V2::Plate).to receive(:find_all)
            .with({ barcode: barcodes }, includes: described_class::SOURCE_PLATE_INCLUDES)
            .and_return([parent_1_plate])
        end
        let(:barcodes) { [parent_1_plate.human_barcode] }
        it 'allows plate creation' do
          expect(wells.first.latest_live_cell_count&.value).to eq(1_000_000) # sanity check
          expect(subject).to be_valid
        end
      end
    end

    describe '#source_plates_must_exist' do
      let(:barcodes) { [parent_1_plate.human_barcode, 'NOT-A-PLATE-BARCODE'] }
      before do
        allow(Sequencescape::Api::V2::Plate).to receive(:find_all)
          .with({ barcode: barcodes }, includes: described_class::SOURCE_PLATE_INCLUDES)
          .and_return([parent_1_plate])
      end
      it 'reports the error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:source_plates]).to include(
          format(described_class::SOURCE_PLATES_MUST_EXIST, 'NOT-A-PLATE-BARCODE')
        )
      end
    end

    describe '#wells_with_aliquots_must_have_donor_id' do
      let!(:wells) do
        wells = Array(parent_1_plate.wells[0..3]) + Array(parent_2_plate.wells[0..1])
        wells.each do |well|
          well.state = 'passed'
          well.aliquots.first.study = study_1
          well.aliquots.first.project = project_1
        end
        wells[0].aliquots.first.sample.sample_metadata.donor_id = 1 # OK
        wells[1].aliquots = nil # no aliquots: OK
        wells[2].aliquots = [] # no aliquots: OK
        wells[3].aliquots.first.sample.sample_metadata.donor_id = nil # ERROR
        wells[4].aliquots.first.sample.sample_metadata.donor_id = '' # ERROR
        wells[5].aliquots.first.sample.sample_metadata.donor_id = ' ' # ERROR
        wells
      end
      it 'reports the error' do
        expect(subject).not_to be_valid
        invalid_wells_hash = {
          parent_1_plate.human_barcode => [wells[3].location],
          parent_2_plate.human_barcode => [wells[4].location, wells[5].location]
        }
        formatted_string = invalid_wells_hash.map { |barcode, wells| "#{barcode}: #{wells.join(', ')}" }.join(' ')
        expect(subject.errors[:source_plates]).to include(
          format(described_class::WELLS_WITH_ALIQUOTS_MUST_HAVE_DONOR_ID, formatted_string)
        )
      end
    end

    describe '#wells_with_aliquots_must_have_cell_count' do
      let!(:wells) do
        wells = Array(parent_1_plate.wells[0..2]) + Array(parent_2_plate.wells[0..2]) # Multiple plates
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study_1
          well.aliquots.first.project = project_1
          well.aliquots.first.sample.sample_metadata.donor_id = index + 1
        end
        wells[0].qc_results << create(:qc_result, key: 'live_cell_count', units: 'cells/ml', value: 1_000_000) # OK
        wells[1].state = 'failed' # no cell count: OK because filtered out.
        wells[3].qc_results << create(:qc_result, key: 'live_cell_count', units: 'cells/ml', value: 2_000_000) # OK
        wells
      end
      it 'reports the error' do
        # We should see an error report on index = 2 of plate 1 and
        # index = 1 and 2 of plate 2. They correspond to wells[2], wells[4] and
        # wells[5] in the wells array returned by the let! block.

        expect(subject).not_to be_valid
        invalid_wells_hash = {
          parent_1_plate.human_barcode => [wells[2].location],
          parent_2_plate.human_barcode => [wells[4].location, wells[5].location]
        }
        formatted_string = invalid_wells_hash.map { |barcode, wells| "#{barcode}: #{wells.join(', ')}" }.join(' ')
        expect(subject.errors[:source_plates]).to include(
          format(described_class::WELLS_WITH_ALIQUOTS_MUST_HAVE_CELL_COUNT, formatted_string)
        )
      end
    end
  end
end
