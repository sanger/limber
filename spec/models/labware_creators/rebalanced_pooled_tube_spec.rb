# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabwareCreators::RebalancedPooledTube do
  subject(:creator) { described_class.new(pooling_tube_creator_attribute) }

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:parent_uuid) { SecureRandom.uuid }
  let(:file) { instance_double(ActionDispatch::Http::UploadedFile) }
  let(:pooling_tube_creator_attribute) { { user_uuid:, purpose_uuid:, parent_uuid:, file: } }

  let(:stock_plate) { create(:stock_plate_for_plate, barcode_number: 5) }
  let(:parent_plate) do
    create(
      :plate,
      :has_pooling_metadata,
      uuid: parent_uuid,
      state: 'passed',
      pool_sizes: [2],
      well_factory: :tagged_well,
      well_states: ['passed'] * 2,
      well_uuid_result: 'example-well-uuid-%s',
      for_multiplexing: true,
      stock_plate: stock_plate
    )
  end

  let(:source_plate) { create :plate, uuid: parent_uuid }
  let(:tube_uuid) { 'tube-123' }

  let(:csv_file) { instance_double(LabwareCreators::RebalancedPooledTube::UltimaRebalancingCsvFile) }
  let(:rebalancing_variables) do
    {
      0 => { 'sample' => 'S1', 'barcode' => 'Z001', 'mean_cvg' => 6.69, 'pf_barcode_reads' => 1000,
             'batch_id' => 12_345, 'CovNeed Waf2&3' => 13.01, 'PoolCF Waf2&3' => 1.0933, 'ExpCov Waf2' => 6.505,
             'Average Cov Waf1' => 7.32, 'Vol to pool' => 10.17 },
      1 => { 'sample' => 'S2', 'barcode' => 'Z002', 'mean_cvg' => 5.95, 'pf_reads' => 2000, 'batch_id' => 12_345,
             'CovNeed Waf2&3' => 12.27, 'PoolCF Waf2&3' => 0.917, 'ExpCov Waf2' => 6.135,
             'Average Cov Waf1' => 6.32, 'Vol to pool' => 9.17 }
    }
  end

  before do
    stub_plate(source_plate, stub_search: false)
    allow(csv_file).to receive(:calculate_rebalancing_variables).and_return(rebalancing_variables)
    allow(LabwareCreators::RebalancedPooledTube::UltimaRebalancingCsvFile)
      .to receive(:new).with(file).and_return(csv_file)
  end

  describe 'validations' do
    it 'is invalid without a file' do
      invalid_creator = described_class.new(file: nil)
      invalid_creator.valid?
      expect(invalid_creator.errors[:file]).to include("can't be blank")
    end
  end

  describe '#csv_file' do
    it 'initializes UltimaRebalancingCsvFile with the uploaded file' do
      expect(creator.send(:csv_file)).to eq(csv_file)
    end
  end

  describe '#save' do
    let(:child_tube) do
      # Prepare child tube and stub its lookups.
      child_tube = create(:tube, uuid: tube_uuid)
      stub_labware(child_tube)
      stub_find_by(Sequencescape::Api::V2::Tube, child_tube, custom_includes: 'aliquots')
      child_tube
    end

    let(:specific_tubes_attributes) do
      [
        {
          uuid: purpose_uuid,
          parent_uuids: [parent_uuid],
          child_tubes: [child_tube],
          tube_attributes: [{}]
        }
      ]
    end

    before do
      allow(csv_file).to receive(:valid?).and_return(true)
      stub_plate(parent_plate, stub_search: false)
      allow(Sequencescape::Api::V2::Transfer).to receive(:create!).and_return(true)
      allow(Sequencescape::Api::V2::PolyMetadatum).to receive(:bulk_create).and_return(true)
      allow(Sequencescape::Api::V2::PolyMetadatum).to receive(:as_bulk_payload) do |data|
        data # just return back the input for test assertions
      end
    end

    describe '#save_calculated_metadata_to_tube_aliquots' do
      before do
        expect_specific_tube_creation
        creator.save
      end

      it 'saves the tube and attaches poly_metadata' do
        aliquots = child_tube.aliquots
        expect(Sequencescape::Api::V2::PolyMetadatum).to have_received(:bulk_create).with(
          array_including(
            hash_including(key: 'sample', value: 'S1', metadatable: aliquots[0]),
            hash_including(key: 'barcode', value: 'Z001', metadatable: aliquots[0]),
            hash_including(key: 'mean_cvg', value: 6.69, metadatable: aliquots[0]),
            hash_including(key: 'pf_barcode_reads', value: 1000, metadatable: aliquots[0]),
            hash_including(key: 'CovNeed Waf2&3', value: 13.01, metadatable: aliquots[0]),
            hash_including(key: 'PoolCF Waf2&3', value: 1.0933, metadatable: aliquots[0]),
            hash_including(key: 'ExpCov Waf2', value: 6.505, metadatable: aliquots[0]),
            hash_including(key: 'Average Cov Waf1', value: 7.32, metadatable: aliquots[0]),
            hash_including(key: 'Vol to pool', value: 10.17, metadatable: aliquots[0])
          )
        )
      end
    end
  end
end
