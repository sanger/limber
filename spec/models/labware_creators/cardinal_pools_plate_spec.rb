# frozen_string_literal: true

require 'spec_helper'
# From UAT Actions
# 1. Create Plate
# 2. Update Manifest
# 3. Create Submission

RSpec.describe LabwareCreators::CardinalPoolsPlate, cardinal: true do
  has_a_working_api

  let(:dest_purpose_uuid) { 'dest-purpose' }
  let(:parent_uuid)       { 'example-parent-uuid' }
  let(:child_uuid)        { 'example-dest-uuid' }
  let(:user_uuid)         { 'user-uuid' }
  let(:plate_size)        { 96 }
  let(:child_plate)       { create(:v2_plate, uuid: child_uuid, well_count: plate_size) }

  let(:form_attributes) do
    {
      purpose_uuid: dest_purpose_uuid,
      parent_uuid: parent_uuid,
      user_uuid: user_uuid
    }
  end

  let(:plate) do
    plate1 = create(:v2_plate, uuid: parent_uuid, well_count: plate_size, aliquots_without_requests: 1)

    plate1.wells[0..3].map { |well| well['state'] = 'failed' }
    plate1.wells[4..95].map { |well| well['state'] = 'passed' }
    supplier_group1 = plate1.wells[0..9]
    supplier_group1.map { |well| well.aliquots.first.sample.sample_metadata[:supplier_name] = 'blood location 1' }
    supplier_group2 = plate1.wells[9..49]
    supplier_group2.map { |well| well.aliquots.first.sample.sample_metadata[:supplier_name] = 'blood location 2' }
    supplier_group3 = plate1.wells[49..95]
    supplier_group3.map { |well| well.aliquots.first.sample.sample_metadata[:supplier_name] = 'blood location 3' }
    plate1
  end

  before do
    allow(subject).to receive(:parent).and_return(plate)
  end

  subject do
    LabwareCreators::CardinalPoolsPlate.new(api, form_attributes)
  end

  context 'on new' do
    it 'can be initialised' do
      expect(subject).to be_a LabwareCreators::CardinalPoolsPlate
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
  end

  context '#source_plate' do
    it 'returns the plate' do
      stub_v2_plate(plate, stub_search: false)
      expect(subject.source_plate).to eq(plate)
    end
  end

  context '#passed_parent_wells' do
    before do
      stub_v2_plate(plate, stub_search: false)
    end

    it 'gets the passed samples for the parent plate' do
      expect(subject.passed_parent_wells.count).to eq(92)
    end

    it 'gets the passed samples for the parent plate' do
      plate.wells[4]['state'] = 'failed'
      expect(subject.passed_parent_wells.count).to eq(91)
    end
  end

  context '#number_of_pools' do
    before do
      stub_v2_plate(plate, stub_search: false)
    end

    # 4 failed
    it 'has 92 passed samples' do
      expect(subject.number_of_pools).to eq(8)
    end

    # 41 failed
    it 'has 55 passed samples' do
      plate.wells[4..40].map { |well| well['state'] = 'failed' }
      expect(subject.number_of_pools).to eq(5)
    end

    # 75 failed
    it 'has 21 passed samples' do
      plate.wells[4..74].map { |well| well['state'] = 'failed' }
      expect(subject.number_of_pools).to eq(2)
    end
  end

  context '#transfer_material_from_parent!' do
    # TODO
    # it 'makes the expected requests' do
    #   stub_v2_plate(child_plate, stub_search: false)
    #   expect(subject.transfer_material_from_parent!(child_uuid)).to eq true
    #   expect(transfer_creation_request).to have_been_made
    # end
  end

  context '#create_sample' do
    # TODO
  end

  context '#get_well_for_plate_location' do
    it 'returns the well for a given plate and location' do
      expect(subject.get_well_for_plate_location(child_plate, "A1")).to eq child_plate.wells[0]
    end
  end

  context '#add_sample_to_well_and_update_aliquot' do
    # TODO

    # let(:sample)  { create(:v2_sample) }

    # before do
    #   allow(subject).to receive(:get_well_for_plate_location).and_return(Hashie::Mash.new({ 'id': 1 }))

    #   well_mock = child_plate.wells[0]
    #   allow(Sequencescape::Api::V2::Well).to receive(:where).with(id: 1).and_return([well_mock])
    # end

    # it 'adds the sample to the well and updates the aliquot' do
    #   subject.add_sample_to_well_and_update_aliquot(sample, child_plate, "A1")
    # end
  end

  context '#create_submission_for_dest_plate' do
    before do
      stub_v2_plate(plate, stub_search: false)

      purpose_config = Hashie::Mash.new({'submission_options': {'Cardinal library prep': { template_name: 'example', request_options: { option: 1 } }}})
      allow(subject).to receive(:purpose_config).and_return purpose_config
      Settings.submission_templates = { 'example': SecureRandom.uuid }
      allow_any_instance_of(SequencescapeSubmission).to receive(:save).and_return true
    end

    it 'creates a submission request' do
      result = subject.create_submission_for_dest_plate(child_plate)
      expect(result).to eq true
    end
  end

  # context '#transfer_request_attributes' do
  #   it 'returns a list of request_hash' do
  #     expect(subject.transfer_request_attributes(child_plate).count).to eq 92
  #   end

  #   it 'calls request_hash for each passed source well' do
  #     allow(subject).to receive(:request_hash)
  #     expect(subject).to receive(:request_hash).exactly(92).times
  #     subject.transfer_request_attributes(child_plate)
  #   end
  # end

  # context '#request_hash' do
  #   it 'returns a hash with the well source and well target info, 92 passed samples' do
  #     passed_source_well = plate.wells[4] # supplier_group1, pool 5 = E1

  #     result = subject.request_hash(passed_source_well, child_plate, {})

  #     expected_dest_well = child_plate.wells.detect do |dest_well|
  #       dest_well.location == subject.transfer_hash[passed_source_well.location][:dest_locn]
  #     end

  #     expect(result).to eq({ 'source_asset' => passed_source_well.uuid, 'target_asset' => expected_dest_well.uuid })
  #   end
  # end

  context '#dest_coordinates' do
    it 'returns a list of A1 -> H1' do
      expect(subject.dest_coordinates).to include('A1', 'H1')
      expect(subject.dest_coordinates.count).to eq(8)
    end
  end

  context '#dest_coordinates_filled_with_a_compound_sample' do
    before do
      transfer_hash = {
        "A4"=>{:dest_locn=>"A1"},
        "A11"=>{:dest_locn=>"A1"},
        "C5"=>{:dest_locn=>"B1"},
      }

      allow(subject).to receive(:transfer_hash).and_return(transfer_hash)
    end

    it 'returns a list of coordinates that contain a sample' do
      expect(subject.dest_coordinates_filled_with_a_compound_sample.count).to eq(2)
      expect(subject.dest_coordinates_filled_with_a_compound_sample).to include('A1', 'B1')
    end
  end

  context '#dest_wells_filled_with_a_compound_sample' do
    before do
      allow(subject).to receive(:dest_coordinates_filled_with_a_compound_sample).and_return(['A1', 'B1'])
    end

    it 'returns a list of coordinates that contain a sample' do
      expect(subject.dest_wells_filled_with_a_compound_sample(child_plate).count).to eq(2)
      expect(subject.dest_wells_filled_with_a_compound_sample(child_plate)).to eq [child_plate.wells[0], child_plate.wells[1]]
    end
  end

  describe '#transfer_hash' do
    before do
      stub_v2_plate(plate, stub_search: false)
    end

    context 'when there are 92 passed samples' do
      it 'returns an object where passed source well keys map to pool destination well' do
        result = subject.transfer_hash
        expect(result.length).to eq(92)
        expect(result.map { |_k, v| v[:dest_locn] }.uniq).to eq subject.dest_coordinates
      end
    end

    context 'when there are 21 passed samples' do
      it 'returns an object where passed source well keys map to pool destination well' do
        plate.wells[4..74].map { |well| well['state'] = 'failed' }
        result = subject.transfer_hash
        expect(result.length).to eq(21)
        expected_dest_coordinates = subject.dest_coordinates[0..1] # [A1, B1] as 21 passed samples has 2 pools
        expect(result.map { |_k, v| v[:dest_locn] }.uniq).to eq expected_dest_coordinates
      end
    end
  end

  describe '#build_pools' do
    before do
      stub_v2_plate(plate, stub_search: false)
    end
    it 'return a list of length equal to the config number_of_pools' do
      expect(subject.build_pools.length).to eq(8)
    end

    it 'a sample should only be in one pool' do
      result = subject.build_pools
      expect(result.flatten.uniq.count).to eq 92
    end

    context 'returns a nested list with samples allocated to the correct number of pools' do
      it 'returns a list of 8 pools, each with 96 passed samples' do
        plate.wells[0..3].map { |well| well['state'] = 'passed' }
        result_pools = subject.build_pools
        expect(result_pools.each.map(&:count)).to eq([12, 12, 12, 12, 12, 12, 12, 12])
      end

      it 'returns a list of 5 pools, each with 55 passed samples' do
        plate.wells[4..40].map { |well| well['state'] = 'failed' }
        result_pools = subject.build_pools
        expect(result_pools.each.map(&:count)).to eq([11, 11, 11, 11, 11])
      end

      it 'returns a list of 2 pools, each with 21 passed samples' do
        plate.wells[4..74].map { |well| well['state'] = 'failed' }
        result_pools = subject.build_pools
        expect(result_pools.each.map(&:count)).to eq([11, 10])
      end

      it 'returns a a list of 1 pool, with 10 samples' do
        plate.wells[4..85].map { |well| well['state'] = 'failed' }
        result_pools = subject.build_pools
        expect(result_pools.each.map(&:count)).to eq([10])
      end
    end
  end

  describe '#wells_grouped_by_supplier' do
    before do
      stub_v2_plate(plate, stub_search: false)
    end

    it 'returns whats expected' do
      expect(subject.wells_grouped_by_supplier.count).to eq(3)
    end

    context 'the wells within a supplier group are randomised' do
      it 'returns whats expected' do
        # difficult to test randomness as there is a chance this fails if the randomisation is such that it remains the same order
        expect(subject.wells_grouped_by_supplier['blood location 2']).not_to eq plate.wells[9..49]
      end
    end

    context 'when there are 4 suppliers, but only 3 suppliers contain passed samples' do
      it 'returns whats expected' do
        supplier_group4 = plate.wells[0..3] # contains only failed samples
        supplier_group4.map { |well| well.aliquots.first.sample[:supplier] = 'blood location 4' }
        expect(subject.wells_grouped_by_supplier.count).to eq(3)
        expect(subject.wells_grouped_by_supplier.keys).to match_array ['blood location 3', 'blood location 2', 'blood location 1']
        expect(subject.wells_grouped_by_supplier['blood location 4']).to be_nil
      end
    end
  end
end
