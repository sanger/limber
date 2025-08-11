# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::WellFilterKinnex do
  context 'when filtering a single well' do
    let!(:parent_uuid) { 'example-plate-uuid' }
    let!(:request_type_key) { 'kinnex_prep' }
    let!(:non_kinnex_request_type_key) { 'non_kinnex_prep' }
    let!(:request_type_kinnex) { create :request_type, key: request_type_key }
    let!(:request_type_non_kinnex) { create :request_type, key: non_kinnex_request_type_key }
    let!(:basic_purpose) { 'test-purpose' }
    let!(:labware_creator) do
      LabwareCreators::TubesFromPlateWell.new(purpose_uuid: 'test-purpose', parent_uuid: parent_uuid)
    end
    let!(:plate_size) { 96 }
    let(:request) do
      create :library_request,
             state: 'pending',
             request_type: request_type_kinnex,
             uuid: 'request-0',
             library_type: 'Sample Libarary Type'
    end
    let(:other_request) do
      create :library_request,
             state: 'pending',
             request_type: request_type_non_kinnex,
             uuid: 'request-1',
             library_type: 'Sample Libarary Type'
    end
    let(:well_kinnex) do
      create(:well, name: 'K1', position: { 'name' => 'K1' }, requests_as_source: [request], outer_request: nil)
    end
    let(:well_non_kinnex) do
      create(
        :well,
        name: 'K2',
        position: {
          'name' => 'K2'
        },
        requests_as_source: [other_request],
        outer_request: nil
      )
    end
    let!(:parent_plate) do
      create :plate,
             uuid: parent_uuid,
             barcode_number: '2',
             size: plate_size,
             wells: [well_kinnex, well_non_kinnex],
             outer_requests: nil
    end

    before do
      create :purpose_config, uuid: basic_purpose, creator_class: 'LabwareCreators::TubesFromPlateWell'
      stub_plate(parent_plate, stub_search: false)
    end

    context 'when there are wells with request_type equal to kinnex_prep' do
      subject { described_class.new(creator: labware_creator, request_type_key: request_type_key) }

      let!(:filtered) { subject.filtered }

      it 'returns the wells' do
        expect(filtered.count).to eq(1)
      end

      it 'returns correct kinnex well' do
        expect(filtered[0][0].name).to eq('K1')
      end

      it 'returns the correct outer request for the well' do
        expect(filtered[0][1]).to eq({ outer_request: 'request-0' })
      end
    end
  end
end
