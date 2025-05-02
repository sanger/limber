# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Uses a custom transfer template to transfer material into the new plate
RSpec.describe LabwareCreators::PartialStampedPlateWithoutDilution do
  subject { described_class.new(api, form_attributes) }

  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  has_a_working_api

  # The following table shows the library types for each well on the parent plate.
  # We will create a new plate with library-type-2.
  #
  # A1: no request         - no library type
  # B1: LT-1               - single request with library type (1)
  # C1:                    - empty
  # D1: LT-1, LT-2         - two requests with different library types (1, 2)
  # E1: LT-1, LT-2, LT-3   - three requests with different library types (1, 2, 3)
  # F1:                    - empty
  # G1:                    - empty
  # H1:                    - empty
  # A2:                    - empty
  # B2: LT-2               - single request with library type (2)

  let(:library_type_1) { 'library-type-1' }
  let(:library_type_2) { 'library-type-2' }
  let(:library_type_3) { 'library-type-3' }

  let(:well_a1) { create(:v2_well, location: 'A1', requests_as_source: []) }
  let(:well_b1) do
    create(:v2_well, location: 'B1', requests_as_source: [create(:library_request, library_type: library_type_1)])
  end
  let(:well_d1) do
    create(
      :v2_well,
      location: 'D1',
      requests_as_source: [
        create(:library_request, library_type: library_type_1),
        create(:library_request, library_type: library_type_2)
      ]
    )
  end
  let(:well_e1) do
    create(
      :v2_well,
      location: 'E1',
      requests_as_source: [
        create(:library_request, library_type: library_type_1),
        create(:library_request, library_type: library_type_2),
        create(:library_request, library_type: library_type_3)
      ]
    )
  end
  let(:well_b2) do
    create(:v2_well, location: 'B2', requests_as_source: [create(:library_request, library_type: library_type_2)])
  end

  let(:parent_wells) { [well_a1, well_b1, well_d1, well_e1, well_b2] }

  let(:parent_uuid) { 'uuid' }
  let(:plate) do
    create :v2_plate, uuid: parent_uuid, barcode_number: '2', wells: parent_wells.rotate(2) # unsorted wells
  end
  let(:child_plate) { create :v2_plate, uuid: 'child-uuid', barcode_number: '3' }

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
        request_type_key: well_d1.requests_as_source[1].request_type.key, # Standard
        library_type: well_d1.requests_as_source[1].library_type # library-type-2
      }
    }
  end

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a described_class
    end
  end

  describe '#labware_wells' do
    it 'returns the wells of the parent plate for well_filter in column order' do
      expect(subject.labware_wells).to eq parent_wells # sorted in column order
    end
  end

  describe '#parent_wells_to_transfer' do
    it 'returns the filtered wells from the parent by library type' do
      expect(subject.parent_wells_to_transfer).to eq [well_d1, well_e1, well_b2] # library-type-2
    end
  end

  describe '#get_destination_location' do
    it 'returns the correct destination location for a given source well' do
      expect(subject.get_destination_location(well_d1)).to eq 'A1'
      expect(subject.get_destination_location(well_e1)).to eq 'B1'
      expect(subject.get_destination_location(well_b2)).to eq 'C1'
    end
  end

  describe '#request_hash' do
    it 'returns the correct request hash for a given source well' do
      # From D1 to A1 for the request with library-type-2
      param_d1 = { outer_request: well_d1.requests_as_source[1].uuid }
      hash_d1 = { source_asset: well_d1.uuid, target_asset: child_plate.wells[0].uuid }.merge(param_d1)
      expect(subject.request_hash(well_d1, child_plate, param_d1)).to eq hash_d1

      # From E1 to B1 for the request with library-type-2
      param_e1 = { outer_request: well_e1.requests_as_source[1].uuid }
      hash_e1 = { source_asset: well_e1.uuid, target_asset: child_plate.wells[1].uuid }.merge(param_e1)
      expect(subject.request_hash(well_e1, child_plate, param_e1)).to eq hash_e1

      # From B2 to C1 for the request with library-type-2
      param_b2 = { outer_request: well_b2.requests_as_source[0].uuid }
      hash_b2 = { source_asset: well_b2.uuid, target_asset: child_plate.wells[2].uuid }.merge(param_b2)
      expect(subject.request_hash(well_b2, child_plate, param_b2)).to eq hash_b2
    end
  end
end
