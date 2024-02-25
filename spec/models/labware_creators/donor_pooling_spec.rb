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
  let(:submission_id) { 1 }
  let(:requests) { create_list(:request, 96, submission_id: submission_id)}

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

    it 'returns always the same instance' do
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
end
