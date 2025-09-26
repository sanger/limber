# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::WellFilterAllowingPartials do
  context 'when filtering wells' do
    let(:parent_uuid) { 'example-plate-uuid' }
    let(:plate_size) { 96 }

    let(:well_a1) do
      create(:well, name: 'A1', position: { 'name' => 'A1' }, requests_as_source: [request_a], outer_request: nil)
    end
    let(:well_b1) do
      create(:well, name: 'B1', position: { 'name' => 'B1' }, requests_as_source: [request_b], outer_request: nil)
    end
    let(:well_c1) do
      create(:well, name: 'C1', position: { 'name' => 'C1' }, requests_as_source: [request_c], outer_request: nil)
    end
    let(:well_d1) do
      create(:well, name: 'D1', position: { 'name' => 'D1' }, requests_as_source: [request_d], outer_request: nil)
    end

    let(:parent_plate) do
      create :plate,
             uuid: parent_uuid,
             barcode_number: '2',
             size: plate_size,
             wells: [well_a1, well_b1, well_c1, well_d1],
             outer_requests: nil
    end

    let(:basic_purpose) { 'test-purpose' }
    let(:labware_creator) { LabwareCreators::StampedPlate.new(purpose_uuid: 'test-purpose', parent_uuid: parent_uuid) }

    let(:request_type_key_a) { 'rt_a' }
    let(:request_type_key_b) { 'rt_b' }

    let(:request_type_a) { create :request_type, key: request_type_key_a }
    let(:request_type_b) { create :request_type, key: request_type_key_b }

    let(:library_type_name_a) { 'Library Type A' }
    let(:library_type_name_b) { 'Library Type B' }

    let(:request_state_pending) { 'pending' }

    let(:request_a) do
      create :library_request,
             state: request_state_pending,
             request_type: request_type_a,
             uuid: 'request-0',
             library_type: library_type_name_a
    end
    let(:request_b) do
      create :library_request,
             state: request_state_pending,
             request_type: request_type_a,
             uuid: 'request-1',
             library_type: library_type_name_a
    end
    let(:request_c) do
      create :library_request,
             state: request_state_pending,
             request_type: request_type_a,
             uuid: 'request-2',
             library_type: library_type_name_a
    end
    let(:request_d) do
      create :library_request,
             state: request_state_pending,
             request_type: request_type_a,
             uuid: 'request-3',
             library_type: library_type_name_a
    end

    before do
      create :purpose_config, uuid: basic_purpose, creator_class: 'LabwareCreators::StampedPlate'
      stub_plate(parent_plate, stub_search: false)
    end

    context 'when a state filter is applied' do
      context 'with a valid filter' do
        subject { described_class.new(creator: labware_creator, request_state: 'started') }

        let(:request_a) do
          create :library_request,
                 state: 'started',
                 request_type: request_type_a,
                 uuid: 'request-0',
                 library_type: library_type_name_a
        end

        it 'returns the correct wells' do
          expect(subject.filtered.count).to eq(1)
          expect(subject.filtered[0][0].name).to eq(well_a1.name)
          expect(subject.errors.messages[:base].count).to eq(0)
        end
      end
    end

    context 'when some wells have no requests' do
      let(:well_b1) do
        create(:well, name: 'B1', position: { 'name' => 'B1' }, requests_as_source: [], outer_request: nil)
      end
      let(:well_c1) do
        create(:well, name: 'C1', position: { 'name' => 'C1' }, requests_as_source: [], outer_request: nil)
      end

      context 'with a valid filter for some wells' do
        subject { described_class.new(creator: labware_creator, request_type_key: request_type_key_a) }

        it 'returns the expected wells' do
          expect(subject.filtered.count).to eq(2)
          expect(subject.filtered[0][0].name).to eq(well_a1.name)
          expect(subject.filtered[1][0].name).to eq(well_d1.name)
          expect(subject.errors.messages[:base].count).to eq(0)
        end
      end
    end

    context 'with multiple different requests in a well' do
      let(:request_e) do
        create :library_request,
               state: request_state_pending,
               request_type: request_type_b,
               uuid: 'request-4',
               library_type: library_type_name_b
      end

      let(:well_a1) do
        create(
          :well,
          name: 'A1',
          position: {
            'name' => 'A1'
          },
          requests_as_source: [request_a, request_e],
          outer_request: nil
        )
      end

      context 'with a valid filter for all wells' do
        subject { described_class.new(creator: labware_creator, request_type_key: request_type_key_a) }

        it 'returns all the wells' do
          expect(subject.filtered.count).to eq(4)
          expect(subject.errors.messages[:base].count).to eq(0)
        end
      end

      context 'with a valid filter for a partial subset of the wells' do
        subject { described_class.new(creator: labware_creator, request_type_key: request_type_key_b) }

        # this represents a partial submission of wells on the plate
        it 'returns the expected wells' do
          expect(subject.filtered.count).to eq(1)
          expect(subject.filtered[0][0].name).to eq(well_a1.name)
          expect(subject.errors.messages[:base].count).to eq(0)
        end
      end

      context 'with an invalid filter' do
        subject { described_class.new(creator: labware_creator, request_type_key: 'rt_c') }

        # up to the creator to catch the situation where the filter returns no wells as a validation check
        it 'returns no wells' do
          expect(subject.filtered.count).to eq(0)
          expect(subject.errors.messages[:base].count).to eq(0)
        end
      end
    end
  end
end
