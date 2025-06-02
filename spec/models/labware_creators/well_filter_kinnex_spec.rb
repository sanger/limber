# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::WellFilterKinnex do
  context 'when filtering a single well' do
    let!(:parent_uuid) { 'example-plate-uuid' }
    let!(:request_type_key) { 'kinnex_prep' }
    let!(:request_type_kinnex) { create :request_type, key: request_type_key }
    let!(:basic_purpose) { 'test-purpose' }
    let!(:labware_creator) do
      LabwareCreators::TubesFromPlateWell.new(nil, purpose_uuid: 'test-purpose', parent_uuid: parent_uuid)
    end
    let!(:plate_size) { 96 }
    let(:request) do
      create :library_request,
             state: 'pending',
             request_type: request_type_kinnex,
             uuid: 'request-0',
             library_type: 'Sample Libarary Type'
    end
    let(:well_kinnex) do
      create(:v2_well, name: 'K1', position: { 'name' => 'K1' }, requests_as_source: [request], outer_request: nil)
    end
    let!(:parent_plate) do
      create :v2_plate,
             uuid: parent_uuid,
             barcode_number: '2',
             size: plate_size,
             wells: [well_kinnex],
             outer_requests: nil
    end

    before do
      create :purpose_config, uuid: basic_purpose, creator_class: 'LabwareCreators::TubesFromPlateWell'
      stub_v2_plate(parent_plate, stub_search: false)
    end

    context 'when there are wells with request_type equal to kinnex_prep' do
      subject { described_class.new(creator: labware_creator, request_type_key: request_type_key) }

      it 'returns the well with request type' do
        expect(subject.filtered.count).to eq(1)
      end

      # subject.filtered returns a document as the following structure:
      # [
      #   [
      #     #<Sequencescape::Api::V2::Well: @attributes={
      #       "type" => "wells",
      #       "uuid" => "c9b0bb3d-8c57-4b6f-a6e5-5633d9fbd1cc",
      #       "name" => "K1",
      #       "position" => { "name" => "K1" },
      #       "state" => "passed",
      #       "diluent_volume" => nil,
      #       "pcr_cycles" => nil,
      #       "submit_for_sequencing" => nil,
      #       "sub_pool" => nil,
      #       "coverage" => nil
      #     }>,
      #     [
      #       #<Sequencescape::Api::V2::Request: @attributes={
      #         "type" => "requests",
      #         "uuid" => "request-0",
      #         "id" => "2",
      #         "role" => "WGS",
      #         "priority" => 0,
      #         "state" => "pending",
      #         "options" => {
      #           "pcr_cycles" => 10,
      #           "fragment_size_required_from" => 100,
      #           "fragment_size_required_to" => 200,
      #           "library_type" => "Sample Library Type"
      #         },
      #         "request_type" => #<Sequencescape::Api::V2::RequestType: @attributes={
      #           "type" => "request_types",
      #           "name" => "Request Type",
      #           "key" => "kinnex_prep",
      #           "for_multiplexing" => false
      #         }>,
      #         "pre_capture_pool" => nil,
      #         "submission" => nil,
      #         "primer_panel" => nil
      #       }>
      #     ]
      #   ]
      # ]
      it 'returns correct well' do
        expect(subject.filtered[0][0].name).to eq('K1')
      end

      it 'returns correct request type' do
        expect(subject.filtered[0][1][0].uuid).to include('request-0')
      end
    end
  end
end
