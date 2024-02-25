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
  let(:parent_1_plate) { create(:v2_plate, uuid: parent_1_plate_uuid) }
  let(:parent_2_plate) { create(:v2_plate, uuid: parent_2_plate_uuid) }
  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_1_plate_uuid } }

  before do
    create(:donor_pooling_plate_purpose_config, uuid: child_purpose_uuid)
    # allow(subject).to receive(:parent).and_return(parent_plate)
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

    it 'caches the result' do
      expect(subject.well_filter).to eq(subject.well_filter)
    end
  end

  describe '#source_plates' do
    let(:source_plates) { [parent_1_plate, parent_2_plate] }
    let(:barcodes) { source_plates.map { |plate| plate.barcode.human } }

    before do
      allow(Sequencescape::Api::V2::Plate).to receive(:find_all)
        .with({ barcode: barcodes }, includes: described_class::SOURCE_PLATE_INCLUDES)
        .and_return(source_plates)
    end

    it 'returns the source plates' do
      subject.barcodes = barcodes
      expect(subject.source_plates).to eq([parent_1_plate, parent_2_plate])
    end
  end
end
