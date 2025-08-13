# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::DonorPoolingPlate do
  subject { described_class.new(api, form_attributes) }

  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has a custom page', 'donor_pooling_plate'

  has_a_working_api

  let(:user_uuid) { 'user-uuid' }
  let(:parent_1_plate_uuid) { 'parent-1-plate-uuid' }
  let(:parent_2_plate_uuid) { 'parent-2-plate-uuid' }
  let(:child_purpose_uuid) { 'child-purpose-uuid' }
  let(:child_plate_uuid) { 'child-plate-uuid' }
  let(:number_of_pools) { 8 }
  let(:requests) do
    create_list(
      :scrna_customer_request,
      192,
      submission_id: 1,
      request_metadata: create(:v2_request_metadata, number_of_pools:)
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

  # Usually we need three projects for testing.
  let(:project_1) { create(:v2_project, name: 'project-1-name') }

  # This is the form that includes plate barcodes, submitted by user.
  let(:form_attributes) do
    { purpose_uuid: child_purpose_uuid, parent_uuid: parent_1_plate_uuid, barcodes: barcodes, user_uuid: user_uuid }
  end
  let(:barcodes) { source_plates.map(&:human_barcode) }

  before do
    # Create the pooling config and add to Settings.
    create(:donor_pooling_config)

    # Create the plate purpose config and add to Settings.
    create(:donor_pooling_plate_purpose_config, uuid: child_purpose_uuid)

    # Allow the API call to return two plates by default.
    allow(Sequencescape::Api::V2::Plate).to receive(:find_all).with(
      { barcode: barcodes },
      includes: described_class::SOURCE_PLATE_INCLUDES
    ).and_return(source_plates)
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
      allow(source_well).to receive(:aliquots).and_return([aliquot])
      allow(aliquot).to receive(:request).and_return(request)
      allow(request).to receive(:request_metadata).and_return(request_metadata)
    end

    context 'when all dependencies are present' do
      it 'returns the requested number of pools' do
        allow(request_metadata).to receive(:number_of_pools).and_return(5)
        expect(subject.number_of_pools([source_well])).to eq(5)
      end
    end

    context 'when request_metadata.number_of_pools is nil' do
      it 'raises an error' do
        allow(request_metadata).to receive(:number_of_pools).and_return(nil)
        expect { subject.number_of_pools([source_well]) }.to raise_error(
          StandardError,
          'Number of pools is missing or nil'
        )
      end
    end
  end

  describe '#pools' do
    let(:number_of_pools) { 2 }
    let!(:wells) do # eager!
      wells = Array(parent_1_plate.wells[0..4]) + Array(parent_2_plate.wells[0..4])
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
      end
    end

    it 'builds the pools' do
      pools = subject.pools
      expect(pools.size).to eq(2)
    end

    it 'caches the result' do
      expect(subject.pools).to be(subject.pools) # same instance
    end
  end

  describe '#build_pools' do
    context 'when standard behaviour' do
      let(:studies) { create_list(:v2_study, 2) }
      let(:projects) { create_list(:v2_project, 2) }
      let(:donor_ids) { (1..160).to_a }
      let(:wells) { Array(parent_1_plate.wells[0..24]) }
      let(:number_of_pools) { 2 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = studies[index % 2]
          well.aliquots.first.project = projects[index % 2]
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request = requests[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
        end
      end

      it 'returns correct number of pools' do
        pools = subject.build_pools
        # 2 pools for each of the 2 study-project groups
        expect(pools.size).to eq(4)
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
          expect(number_of_unique_donor_ids).to eq(pool.size)
        end
      end
    end

    # Checks for behaviour using the numbers used in a real lab test run
    context 'when test run for 10 samples per pool and 8 pools' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:donor_ids) { (1..80).to_a }
      let(:wells) { parent_1_plate.wells[0..79] }
      let(:expected_number_of_pools) { 8 }
      let(:number_of_pools) { 8 }
      let(:expected_size_of_pools) { 10 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.request = requests[index]
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
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

      it 'returns pools of the expected size' do
        pools = subject.build_pools
        pools.each { |pool| expect(pool.size).to eq(expected_size_of_pools) }
      end
    end

    context 'when the test run has 32 wells and 8 pools' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:donor_ids) { (1..32).to_a }
      let(:wells) { parent_1_plate.wells[0..31] }
      let(:number_of_pools) { 8 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.request = requests[index]
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
        end
      end

      it 'fails due to pool sizing constraints (5 to 25)' do
        expected_message =
          'Invalid distribution: Each pool must have between ' \
          '5 and 25 wells.'

        expect { subject.build_pools }.to raise_error(expected_message)
      end
    end

    context 'when the test run has 80 wells and 9 pools per study/project group' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:donor_ids) { (1..80).to_a }
      let(:wells) { parent_1_plate.wells[0..79] }
      let(:number_of_pools) { 9 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.request = requests[index]
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
        end
      end

      it 'fails due to number of pool constraints (1 to 8)' do
        expected_message = 'Invalid requested number of pools: must be between 1 and 8. Provided: 9.'

        expect { subject.build_pools }.to raise_error(expected_message)
      end
    end

    context 'when the test run has wells with multiple duplicate donor IDs' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:donor_ids) { (1..40).to_a * 2 } # Repeats 1-40 twice, creating 80 donor IDs
      let(:wells) { parent_1_plate.wells[0..79] }
      let(:expected_number_of_pools) { 4 }
      let(:number_of_pools) { 4 }
      let(:expected_size_of_pools) { 20 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.request = requests[index]
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
        end
        wells[10].aliquots.first.sample.sample_metadata.donor_id = 1
      end

      it 'returns correct number of pools' do
        pools = subject.build_pools
        expect(pools.size).to eq(expected_number_of_pools)
        expect(pools.flatten).to match_array(wells)
      end

      it 'returns pools with correct number of donors' do
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_donor_ids = pool.map { |well| well.aliquots.first.sample.sample_metadata.donor_id }.uniq.size
          expect(number_of_unique_donor_ids).to eq(pool.size)
        end
      end

      it 'returns pools of the expected size' do
        pools = subject.build_pools
        pools.each { |pool| expect(pool.size).to eq(expected_size_of_pools) }
      end
    end

    context 'when the test run has wells with multiple duplicate IDs (shuffled)' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:donor_ids) { (1..20).to_a.shuffle * 4 } # Repeats 1-40 twice, creating 80 donor IDs
      let(:wells) { parent_1_plate.wells[0..79] }
      let(:expected_number_of_pools) { 4 }
      let(:number_of_pools) { 4 }
      let(:expected_size_of_pools) { 20 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.request = requests[index]
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
        end
      end

      it 'returns correct number of pools' do
        pools = subject.build_pools
        expect(pools.size).to eq(expected_number_of_pools)
        expect(pools.flatten).to match_array(wells)
      end

      it 'returns pools with correct number of donors' do
        pools = subject.build_pools
        pools.each do |pool|
          number_of_unique_donor_ids = pool.map { |well| well.aliquots.first.sample.sample_metadata.donor_id }.uniq.size
          expect(number_of_unique_donor_ids).to eq(pool.size)
        end
      end

      it 'returns pools of the expected size' do
        pools = subject.build_pools
        pools.each { |pool| expect(pool.size).to eq(expected_size_of_pools) }
      end
    end

    context 'when the test run cannot distribute wells with duplicate IDs' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      # Only 10 unique donor ids, but 20 samples needed per pool - impossible to distribute correctly
      let(:donor_ids) { (1..10).to_a * 8 }
      let(:wells) { parent_1_plate.wells[0..79] }
      let(:number_of_pools) { 4 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.request = requests[index]
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
        end
        wells[10].aliquots.first.sample.sample_metadata.donor_id = 1
      end

      it 'fails to distribute and raises an error' do
        expected_message = 'Cannot find a pool to assign the well to.'

        expect { subject.build_pools }.to raise_error(expected_message)
      end
    end

    context 'when the groups of donor ids are not ordered largest to smallest' do
      # If don't deal with the largest group first, you might find some pools are full and there aren't
      # enough pools left to split the large group between.
      # This is solved by sorting the wells first, in `reorder_wells_by_donor_id`.
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:wells) { parent_1_plate.wells[0..14] }
      let(:number_of_pools) { 3 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.request = requests[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
        end

        # 4 triplicates, 1 duplicate, 1 single
        wells[0].aliquots.first.sample.sample_metadata.donor_id = 6
        wells[1..2].each_with_index { |well, _index| well.aliquots.first.sample.sample_metadata.donor_id = 5 }
        wells[3..5].each_with_index { |well, _index| well.aliquots.first.sample.sample_metadata.donor_id = 4 }
        wells[6..8].each_with_index { |well, _index| well.aliquots.first.sample.sample_metadata.donor_id = 3 }
        wells[9..11].each_with_index { |well, _index| well.aliquots.first.sample.sample_metadata.donor_id = 2 }
        wells[12..14].each_with_index { |well, _index| well.aliquots.first.sample.sample_metadata.donor_id = 1 }
      end

      it 'works' do
        expect { subject.build_pools }.not_to raise_error
      end
    end

    context 'when the groups of donor ids are ordered largest to smallest' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:wells) { parent_1_plate.wells[0..14] }
      let(:number_of_pools) { 3 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.request = requests[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
        end

        # 4 triplicates, 1 duplicate, 1 single
        wells[0..2].each_with_index { |well, _index| well.aliquots.first.sample.sample_metadata.donor_id = 1 }
        wells[3..5].each_with_index { |well, _index| well.aliquots.first.sample.sample_metadata.donor_id = 2 }
        wells[6..8].each_with_index { |well, _index| well.aliquots.first.sample.sample_metadata.donor_id = 3 }
        wells[9..11].each_with_index { |well, _index| well.aliquots.first.sample.sample_metadata.donor_id = 4 }
        wells[12..13].each_with_index { |well, _index| well.aliquots.first.sample.sample_metadata.donor_id = 5 }
        wells[14].aliquots.first.sample.sample_metadata.donor_id = 6
      end

      it 'works' do
        expect { subject.build_pools }.not_to raise_error
      end
    end

    context 'when the pools are not quite the same size' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:donor_ids) { (1..40).to_a * 2 }
      let(:wells) { parent_1_plate.wells[0..72] }
      let(:expected_number_of_pools) { 4 }
      let(:number_of_pools) { 4 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.request = requests[index]
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
        end
        wells[10].aliquots.first.sample.sample_metadata.donor_id = 1
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

      it 'returns pools of the expected size' do
        pools = subject.build_pools
        expect(pools.map(&:size).sort).to eql([18, 18, 18, 19])
      end
    end

    context 'when test run for 24 samples per pool and 8 pools' do
      let(:study) { create(:v2_study) }
      let(:project) { create(:v2_project) }
      let(:donor_ids) { (1..192).to_a }
      let(:wells) { parent_1_plate.wells + parent_2_plate.wells }
      let(:expected_number_of_pools) { 8 }
      let(:number_of_pools) { 8 }
      let(:expected_size_of_pools) { 24 }

      before do
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study
          well.aliquots.first.project = project
          well.aliquots.first.sample.sample_metadata.donor_id = donor_ids[index]
          well.aliquots.first.request = requests[index]
          well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
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

      it 'returns pools of the expected size' do
        pools = subject.build_pools
        pools.each { |pool| expect(pool.size).to eq(expected_size_of_pools) }
      end
    end
  end

  describe '#transfer_request_attributes' do
    let(:number_of_pools) { 2 }
    let!(:wells) do # eager!
      wells = Array(parent_1_plate.wells[0..4]) + Array(parent_2_plate.wells[0..4])
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
      end
    end

    before do
      # set instance variable used in transfer_request_attributes method
      subject.instance_variable_set(:@dest_plate, child_plate)
    end

    it 'returns the transfer request attributes into destination plate' do
      attributes = subject.transfer_request_attributes(child_plate)
      expect(attributes.size).to eq(10)

      expect(attributes[0][:source_asset]).to eq(wells[0].uuid)
      expect(attributes[0][:target_asset]).to eq(child_plate.wells[0].uuid)
      expect(attributes[0][:aliquot_attributes]).to eq({ tag_depth: '1' })
      expect(attributes[0][:submission_id]).to eq('1') # request factory insists on string

      expect(attributes[1][:source_asset]).to eq(wells[1].uuid)
      expect(attributes[1][:target_asset]).to eq(child_plate.wells[0].uuid)
      expect(attributes[1][:aliquot_attributes]).to eq({ tag_depth: '2' })
      expect(attributes[1][:submission_id]).to eq('1') # request factory insists on string
    end
  end

  describe '#request_hash' do
    let(:number_of_pools) { 1 }
    let(:wells) do
      wells = Array(parent_1_plate.wells[0..4])
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
      end
    end

    before do
      # set instance variable used in transfer_request_attributes method
      subject.instance_variable_set(:@dest_plate, child_plate)
    end

    it 'returns the request hash' do
      hash = subject.request_hash(wells[0], child_plate, { submission_id: '1' })
      expect(hash[:source_asset]).to eq(wells[0].uuid)
      expect(hash[:target_asset]).to eq(child_plate.wells[0].uuid)
      expect(hash[:aliquot_attributes]).to eq({ tag_depth: '1' })
      expect(hash[:submission_id]).to eq('1')

      hash = subject.request_hash(wells[1], child_plate, { submission_id: '1' })
      expect(hash[:source_asset]).to eq(wells[1].uuid)
      expect(hash[:target_asset]).to eq(child_plate.wells[0].uuid)
      expect(hash[:aliquot_attributes]).to eq({ tag_depth: '2' })
      expect(hash[:submission_id]).to eq('1')
    end
  end

  describe '#transfer_hash' do
    let(:number_of_pools) { 1 }
    let!(:wells) do
      wells = Array(parent_1_plate.wells[0..4]) + Array(parent_2_plate.wells[0..4])
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
        well.aliquots.first.request = requests[index]
        well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools
      end
    end

    it 'returns the transfer hash' do
      hash = wells[0..9].index_with { |_well| { dest_locn: 'A1' } }
      expect(subject.transfer_hash).to eq(hash)
    end

    it 'caches the result' do
      expect(subject.transfer_hash).to be(subject.transfer_hash) # same instance
    end
  end

  describe '#tag_depth_hash' do
    let(:number_of_pools) { 2 }

    it 'returns a hash mapping positions of wells in their pools' do
      wells = Array(parent_1_plate.wells[0..4]) + Array(parent_2_plate.wells[0..4])
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
      end

      wells[1].state = 'passed'
      wells[1].aliquots.first.study = study_1
      wells[1].aliquots.first.project = project_1
      wells[1].aliquots.first.sample.sample_metadata.donor_id = 1 # same donor as the first well

      subject.build_pools
      expect(subject.tag_depth_hash[wells[0]]).to eq('1') # 10-well-A1, Pool 1
      expect(subject.tag_depth_hash[wells[2]]).to eq('2') # 10-well-C1, Pool 1
      expect(subject.tag_depth_hash[wells[3]]).to eq('3') # 10-well-D1, Pool 2
      expect(subject.tag_depth_hash[wells[4]]).to eq('4') # 10-well-E1, Pool 1
      expect(subject.tag_depth_hash[wells[5]]).to eq('5') # 13-well-A1, Pool 2

      expect(subject.tag_depth_hash[wells[1]]).to eq('1') # 10-well-B1, Pool 2
      expect(subject.tag_depth_hash[wells[6]]).to eq('2') # 13-well-B1, Pool 1
      expect(subject.tag_depth_hash[wells[7]]).to eq('3') # 13-well-C1, Pool 2
      expect(subject.tag_depth_hash[wells[8]]).to eq('4') # 13-well-D1, Pool 1
      expect(subject.tag_depth_hash[wells[9]]).to eq('5') # 13-well-E1, Pool 2
    end

    it 'caches the result' do
      wells = Array(parent_1_plate.wells[0..9])
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
      end

      subject.build_pools
      expect(subject.tag_depth_hash).to be(subject.tag_depth_hash) # same instance
    end
  end

  describe '#transfer_material_from_parent!' do
    let(:cells_per_chip_well) { 90_000 }
    let(:allowance_band) { '2 pool attempts, 2 counts' }

    let(:requests) do
      Array.new(10) do |_i|
        create :scrna_customer_request,
               request_metadata: create(:v2_request_metadata, number_of_pools:, cells_per_chip_well:, allowance_band:)
      end
    end

    let(:number_of_pools) { 2 }
    let!(:wells) do # eager!
      wells = Array(parent_1_plate.wells[0..4]) + Array(parent_2_plate.wells[0..4])
      wells.each_with_index do |well, index|
        well.state = 'passed'
        well.aliquots.first.study = study_1 # same study
        well.aliquots.first.project = project_1 # same project
        well.aliquots.first.sample.sample_metadata.donor_id = index + 1 # different donors
        well.aliquots.first.request = requests[index]
      end
    end

    let(:transfer_requests_attributes) { subject.transfer_request_attributes(child_plate) }

    before { stub_v2_plate(child_plate) }

    let!(:stub_metadata_creation) { stub_api_v2_save('PolyMetadatum') }

    it 'posts transfer requests to Sequencescape' do
      expect_transfer_request_collection_creation

      subject.transfer_material_from_parent!(child_plate.uuid)
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
        allow(Sequencescape::Api::V2::Plate).to receive(:find_all).with(
          { barcode: barcodes },
          includes: described_class::SOURCE_PLATE_INCLUDES
        ).and_return([parent_1_plate])
      end

      let(:barcodes) { [parent_1_plate.human_barcode] * 2 }

      it 'reports the error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:source_barcodes]).to include(described_class::SOURCE_BARCODES_MUST_BE_DIFFERENT)
      end

      context 'with single barcode' do
        let(:number_of_pools) { 1 }
        let!(:wells) do
          Array.new(5) do |index|
            well = parent_1_plate.wells[index]
            well.state = 'passed'
            well.aliquots.first.study = study_1
            well.aliquots.first.project = project_1
            well.aliquots.first.sample.sample_metadata.donor_id = "donor_#{index}"
            well.aliquots.first.request = requests[index]
            well.aliquots.first.request.request_metadata.number_of_pools = number_of_pools

            # TODO: are we changing this to total cell count?
            well.qc_results << create(:qc_result, key: 'live_cell_count', units: 'cells/ml', value: 1_000_000)
            well
          end
        end
        before do
          allow(Sequencescape::Api::V2::Plate).to receive(:find_all).with(
            { barcode: barcodes },
            includes: described_class::SOURCE_PLATE_INCLUDES
          ).and_return([parent_1_plate])
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
        allow(Sequencescape::Api::V2::Plate).to receive(:find_all).with(
          { barcode: barcodes },
          includes: described_class::SOURCE_PLATE_INCLUDES
        ).and_return([parent_1_plate])
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

    describe '#validate_pools_can_be_built' do
      # In this test, we have 6 wells, 2 of which have the same donor ID but
      # number_of_pools is 1. It will raise an exception because it cannot
      # distribute the wells. We test that the exception is caught and
      # converted to an error message.
      let(:number_of_pools) { 1 }
      let!(:wells) do
        wells = Array(parent_1_plate.wells[0..5])
        wells.each_with_index do |well, index|
          well.state = 'passed'
          well.aliquots.first.study = study_1
          well.aliquots.first.project = project_1
          well.aliquots.first.sample.sample_metadata.donor_id = index + 1
        end
        wells
      end

      before { wells[0..1].map { |well| well.aliquots.first.sample.sample_metadata.donor_id = 'DUPLICATE' } }

      it 'converts exceptions to errors' do
        exception_message = 'Cannot find a pool to assign the well to.'
        allow(subject).to receive(:raise).and_call_original # spy on raise

        expect(subject).not_to be_valid

        expect(subject).to have_received(:raise).with(exception_message)
        expect(subject.errors[:pools]).to include(exception_message)
      end
    end
  end

  describe '#stable_sort_hash_by_values_size_desc' do
    context 'when the values are all of the same size' do
      it 'maintains the original order' do
        the_hash = { 'a' => ['1'], 'b' => ['2'], 'c' => ['3'] }

        # normal sort by actually maintained the order in this case,
        # but the stable sorting was necessary for more realistic inputs
        result = subject.stable_sort_hash_by_values_size_desc(the_hash)

        sorted = [['a', ['1']], ['b', ['2']], ['c', ['3']]]

        expect(result).to eq(sorted)
      end
    end

    context 'when the values are of differing sizes' do
      it 'orders by values size descending while retaining the order for values of equal size' do
        the_hash = { 'a' => ['1'], 'b' => %w[2 5 4], 'c' => ['3'] }

        result = subject.stable_sort_hash_by_values_size_desc(the_hash)

        sorted = [['b', %w[2 5 4]], ['a', ['1']], ['c', ['3']]]

        expect(result).to eq(sorted)
      end
    end
  end
end
