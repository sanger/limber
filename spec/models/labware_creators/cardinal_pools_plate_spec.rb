# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::CardinalPoolsPlate, cardinal: true do
  has_a_working_api

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:parent_uuid)        { 'example-plate-uuid' }
  let(:user_uuid)          { 'user-uuid' }
  let(:plate_size) { 96 }

  let(:form_attributes) do
    {
      purpose_uuid: child_purpose_uuid,
      parent_uuid: parent_uuid,
      user_uuid: user_uuid
    }
  end

  let(:plate) do
    plate1 = create(:v2_plate, uuid: parent_uuid, well_count: plate_size, aliquots_without_requests: 1)

    plate1.wells[0..3].map { |well| well['state'] = 'failed' }
    plate1.wells[4..95].map { |well| well['state'] = 'passed' }
    supplier_group1 = plate1.wells[0..9]
    supplier_group1.map { |well| well.aliquots.first.sample[:supplier] = 'blood location 1' }
    supplier_group2 = plate1.wells[9..49]
    supplier_group2.map { |well| well.aliquots.first.sample[:supplier] = 'blood location 2' }
    supplier_group3 = plate1.wells[49..95]
    supplier_group3.map { |well| well.aliquots.first.sample[:supplier] = 'blood location 3' }
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
      expect(subject.class.pooling_config[96]).to eq(8)
      expect(subject.class.pooling_config[87]).to eq(7)
      expect(subject.class.pooling_config[76]).to eq(6)
      expect(subject.class.pooling_config[65]).to eq(5)
      expect(subject.class.pooling_config[52]).to eq(4)
      expect(subject.class.pooling_config[39]).to eq(3)
      expect(subject.class.pooling_config[26]).to eq(2)
      expect(subject.class.pooling_config[20]).to eq(1)
    end
  end

  context '#passed_parent_samples' do
    it 'gets the passed samples for the parent plate' do
      expect(subject.passed_parent_samples.count).to eq(92)
    end
  end

  context '#transfer_hash' do
    it 'returns whats expected' do
      expect(subject.transfer_hash).to eq({ A1: { dest_locn: 'H12' } })
    end
  end

  context '#samples_grouped_by_supplier' do
    it 'returns whats expected' do
      expect(subject.samples_grouped_by_supplier.count).to eq(3)
    end
  end

  context 'number_of_pools' do
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

  context '#build_pools' do
    it 'returns a nested list with samples allocated to the correct number of pools' do
      expect(subject.build_pools.length).to eq(8)
    end
  end
end

# context 'when wells are missing a concentration value' do
#   let(:well_e1) do
#     create(:v2_well,
#            position: { 'name' => 'E1' },
#            qc_results: [])
#   end

#   let(:parent_plate) do
#     create :v2_plate,
#            uuid: parent_uuid,
#            barcode_number: '2',
#            size: plate_size,
#            wells: [well_a1, well_b1, well_c1, well_d1, well_e1],
#            outer_requests: requests
#   end

#   it 'fails validation' do
#     expect(subject).to_not be_valid
#   end
# end
