# frozen_string_literal: true

require 'spec_helper'
# require 'labware_creators/base'
# require_relative '../../support/shared_tagging_examples'
# require_relative 'shared_examples'

# Presents the user with a form allowing them to scan in up to four plates
# which will then be pooled together according to pre-capture pools
RSpec.describe LabwareCreators::CardinalPoolsPlate, cardinal: true do
  # it_behaves_like 'it only allows creation from tagged plates'

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
    plate1 = create(
      :v2_stock_plate, uuid: parent_uuid, barcode_number: '2', 
        size: plate_size, outer_requests: [],
        well_count: 96, pool_sizes: [], aliquots_without_requests: 1
    )
    #plate1 = create :v2_plate, uuid: parent_uuid, barcode_number: '2', size: plate_size, outer_requests: []
    #plate2 = create :plate
    # plate1 has plate_size - 4 'passed' samples = 92
    # these "passed" samples would be grouped into 8 pools (defined in csv config)
    # with the first 4 pools containing 12 samples
    # and the second 4 pools containing 11 samples
    # where the pools, where possible, contain samples from more that one blood location
    # these 8 pools would then be added to 8 wells in the destination plate
    plate1.wells[0..3].map { |well| well["state"] = "failed"}

    supplier_group_1 = plate1.wells[0..9]
    supplier_group_1.map { |well| well.aliquots.first.sample["supplier"] = "blood location 1"}
    supplier_group_2 = plate1.wells[9..49]
    supplier_group_2.map { |well| well.aliquots.first.sample["supplier"] = "blood location 2"}
    supplier_group_3 = plate1.wells[49..95]
    supplier_group_3.map { |well| well.aliquots.first.sample["supplier"] = "blood location 3"}
    plate1
  end

  before do
    # create(:purpose_config, name: child_purpose_name, uuid: child_purpose_uuid)
    # stub_v2_plate(child_plate, stub_search: false)
    stub_v2_plate(plate, stub_search: false)
  end

  subject do
    LabwareCreators::CardinalPoolsPlate.new(api, form_attributes)
  end

  context 'on new' do
    it 'can be initialised' do
      expect(subject).to be_a LabwareCreators::CardinalPoolsPlate
    end

    
    it 'has the config loaded' do
      file_content = CSV.read('config/cardinal_pooling.csv', { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all })
      expected_dict = {}
      expected_csv = file_content.map { |d| expected_dict[d.to_hash[:number]] = d.to_hash }
      expect(subject.class.pooling_config).to eq(expected_dict)
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
  end

  context '#get_passed_parent_samples' do
    it 'gets the passed samples for the parent plate' do
      expect(subject.get_passed_parent_samples.count).to eq(92)
    end
  end

  context '#get_config_for_number_of_passed_samples' do
    it 'gets the passed samples for the parent plate' do
      expect(subject.get_config_for_number_of_passed_samples).to eq({:number=>92, :pool_1=>12, :pool_2=>12, :pool_3=>12, :pool_4=>12, :pool_5=>11, :pool_6=>11, :pool_7=>11, :pool_8=>11})
    end    
  end

  context '#transfer_hash' do
    it 'returns whats expected' do
      expect(subject.transfer_hash).to eq({"A1": {"dest_locn": "H12"}})
    end
  end

  context '#pool_passed_samples_containing_more_than_one_blood_location' do
    it 'returns whats expected' do
      expect(subject.pool_passed_samples_containing_more_than_one_blood_location).to eq({ pool_1: [], pool_2: [], pool_3: [], pool_4: [], pool_5: [], pool_6: [], pool_7: [], pool_8: [] })
    end
  end

  context '#group_samples_by_supplier' do
    it 'returns whats expected' do
      expected = {0=>plate1.wells[0..9], 1=>plate1.wells[9..49], 2=>plate1.wells[49..95]}
      expect(subject.group_samples_by_supplier).to eq({ pool_1: [], pool_2: [], pool_3: [], pool_4: [], pool_5: [], pool_6: [], pool_7: [], pool_8: [] })
    end
  end
end