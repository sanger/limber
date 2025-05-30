# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::WellFilterComposite do
  context 'when filtering wells' do
    let(:parent_uuid) { 'example-plate-uuid' }
    let(:request_type_key) { 'kinnex_prep' }
    let!(:request_type_kinnex) { create :request_type, key: request_type_key }
    let(:basic_purpose) { 'test-purpose' }
    let(:labware_creator) do
      LabwareCreators::TubesFromPlateWell.new(nil, purpose_uuid: 'test-purpose', parent_uuid: parent_uuid)
    end

    before do
      create :purpose_config, uuid: basic_purpose, creator_class: 'LabwareCreators::TubesFromPlateWell'
      stub_v2_plate(parent_plate, stub_search: false)
    end

    context 'when there are wells with request_type equal to kinnex_prep' do
      subject { described_class.new(creator: labware_creator, request_type_key: request_type_key)
      let(:request) do
        create :library_request,
               state: 'pending',
               request_type: request_type_kinnex,
               uuid: 'request-0',
               library_type: 'Sample Libarary Type'
      end
      let(:well_kinnex) {
        create(:v2_well, name: 'K1', position: { 'name' => 'K1' }, requests_as_source: [request], outer_request: nil)
      }
      let(:parent_plate) {
        create :v2_plate,
               uuid: parent_uuid,
               barcode_number: '2',
               size: plate_size,
               wells: [well_kinnex],
               outer_requests: nil
      } }

      it 'returns the well with kinnex_prep request type', skip: 'WIP' do
        expect(subject.filtered.count).to eq(1)
        expect(subject.filtered[0][0].name).to eq('K1')
      end
    end

  end
end
