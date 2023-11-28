# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative '../../support/shared_tagging_examples'
require_relative 'shared_examples'

# Uses a custom transfer template to transfer material into the new plate
RSpec.describe LabwareCreators::PartialStampedPlateWithoutDilution do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  has_a_working_api

  let(:well_a1) do
    create(:v2_well, name: 'A1', position: { 'name' => 'A1' }, requests_as_source: [requests[0]], outer_request: nil)
  end
  let(:well_b1) do
    create(:v2_well, name: 'B1', position: { 'name' => 'B1' }, requests_as_source: [requests[1]], outer_request: nil)
  end
  let(:well_c1) do
    create(:v2_well, name: 'C1', position: { 'name' => 'C1' }, requests_as_source: [requests[2]], outer_request: nil)
  end
  let(:well_d1) do
    create(:v2_well, name: 'D1', position: { 'name' => 'D1' }, requests_as_source: [requests[3]], outer_request: nil)
  end
  let(:parent_uuid) { 'uuid' }
  let(:plate_size) { 96 }
  let(:plate) do
    create :v2_plate,
           uuid: parent_uuid,
           barcode_number: '2',
           size: plate_size,
           wells: [well_a1, well_b1, well_c1, well_d1],
           outer_requests: requests
  end
  let(:child_plate) do
    create :v2_plate, uuid: 'child-uuid', barcode_number: '3', size: plate_size, outer_requests: requests
  end

  let(:requests) do
    Array.new(4) do |i|
      create :library_request, state: 'pending', uuid: "request-#{i}", library_type: "library-type-#{i}"
    end
  end

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  before do
    create(:purpose_config, name: child_purpose_name, uuid: child_purpose_uuid)
    stub_v2_plate(plate, stub_search: false)
    stub_v2_plate(child_plate, stub_search: false)
  end

  let(:form_attributes) do
    {
      purpose_uuid: child_purpose_uuid,
      parent_uuid: parent_uuid,
      user_uuid: user_uuid,
      filters: {
        request_type_key: requests[3].request_type.key,
        library_type: requests[3].library_type
      }
    }
  end

  subject { described_class.new(api, form_attributes) }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a described_class
    end
  end

  describe '#labware_wells' do
    it 'returns the wells of the parent plate for well_filter in column order' do
      expect(subject.labware_wells).to eq [well_a1, well_b1, well_c1, well_d1]
    end
  end

  describe '#parent_wells_to_transfer' do
    it 'returns the filtered wells from the parent by library type' do
      expect(subject.parent_wells_to_transfer).to eq [well_d1]
    end
  end

  describe '#get_destination_location' do
    it 'returns the correct destination location for a given source well' do
      expect(subject.get_destination_location(well_d1)).to eq 'A1'
    end
  end

  describe '#request_hash' do
    it 'returns the correct request hash for a given source well' do
      additional_parameters = { outer_request: requests[3].uuid }
      hash =
        { 'source_asset' => well_d1.uuid, 'target_asset' => child_plate.wells[0].uuid }.merge(additional_parameters)

      expect(subject.request_hash(well_d1, child_plate, additional_parameters)).to eq hash
    end
  end
end
