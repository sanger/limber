# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::WellFilter do
  context 'when filtering wells' do
    let(:parent_uuid) { 'example-plate-uuid' }
    let(:plate_size) { 96 }

    let(:well_a1) do
      create(:well, position: { 'name' => 'A1' }, requests_as_source: [request_a], outer_request: nil)
    end
    let(:well_b1) do
      create(:well, position: { 'name' => 'B1' }, requests_as_source: [request_b], outer_request: nil)
    end
    let(:well_c1) do
      create(:well, position: { 'name' => 'C1' }, requests_as_source: [request_c], outer_request: nil)
    end
    let(:well_d1) do
      create(:well, position: { 'name' => 'D1' }, requests_as_source: [request_d], outer_request: nil)
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

    let(:request_a) do
      create :library_request,
             state: 'pending',
             request_type: request_type_a,
             uuid: 'request-0',
             library_type: library_type_name_a
    end
    let(:request_b) do
      create :library_request,
             state: 'pending',
             request_type: request_type_a,
             uuid: 'request-1',
             library_type: library_type_name_a
    end
    let(:request_c) do
      create :library_request,
             state: 'pending',
             request_type: request_type_a,
             uuid: 'request-2',
             library_type: library_type_name_a
    end
    let(:request_d) do
      create :library_request,
             state: 'pending',
             request_type: request_type_a,
             uuid: 'request-3',
             library_type: library_type_name_a
    end

    before do
      create :purpose_config, uuid: basic_purpose, creator_class: 'LabwareCreators::StampedPlate'
      stub_plate(parent_plate, stub_search: false)
    end

    context 'without any additional filtering' do
      subject { described_class.new(creator: labware_creator) }

      it 'returns all the wells' do
        expect(subject.filtered.count).to eq(4)
        expect(subject.errors.messages[:base].count).to eq(0)
      end
    end

    context 'when a request type filter is applied' do
      context 'with a valid filter' do
        subject { described_class.new(creator: labware_creator, request_type_key: request_type_key_a) }

        it 'returns all the wells' do
          expect(subject.filtered.count).to eq(4)
          expect(subject.errors.messages[:base].count).to eq(0)
        end
      end

      context 'with an invalid filter' do
        subject { described_class.new(creator: labware_creator, request_type_key: request_type_key_b) }

        it 'raises an exception' do
          expect { subject.filtered }.to raise_error(LabwareCreators::WellFilter::FilterError)

          # none of the wells have a request with the correct request type
          expect(subject.errors.messages[:base].count).to eq(4)
        end
      end
    end

    context 'when a library type filter is applied' do
      context 'with a valid filter' do
        subject { described_class.new(creator: labware_creator, library_type: library_type_name_a) }

        it 'returns all the wells' do
          expect(subject.filtered.count).to eq(4)
          expect(subject.errors.messages[:base].count).to eq(0)
        end
      end

      context 'with an invalid filter' do
        subject { described_class.new(creator: labware_creator, library_type: library_type_name_b) }

        it 'raises an exception' do
          expect { subject.filtered }.to raise_error(LabwareCreators::WellFilter::FilterError)

          # none of the wells have a request with the correct library type
          expect(subject.errors.messages[:base].count).to eq(4)
        end
      end
    end

    context 'when a valid request and library type filter is applied' do
      subject do
        described_class.new(
          creator: labware_creator,
          request_type_key: request_type_key_a,
          library_type: library_type_name_a
        )
      end

      it 'returns all the wells' do
        expect(subject.filtered.count).to eq(4)
        expect(subject.errors.messages[:base].count).to eq(0)
      end
    end

    context 'with multiple different requests in a well' do
      let(:request_e) do
        create :library_request,
               state: 'pending',
               request_type: request_type_b,
               uuid: 'request-4',
               library_type: library_type_name_b
      end

      let(:well_a1) do
        create(:well, position: { 'name' => 'A1' }, requests_as_source: [request_a, request_e], outer_request: nil)
      end

      context 'with a valid filter' do
        subject { described_class.new(creator: labware_creator, request_type_key: request_type_key_a) }

        it 'returns all the wells' do
          expect(subject.filtered.count).to eq(4)
          expect(subject.errors.messages[:base].count).to eq(0)
        end
      end

      context 'with an invalid filter' do
        subject { described_class.new(creator: labware_creator, request_type_key: request_type_key_b) }

        it 'raises an exception' do
          expect { subject.filtered }.to raise_error(LabwareCreators::WellFilter::FilterError)

          # 3 of the 4 wells do not have a request with the correct type
          expect(subject.errors.messages[:base].count).to eq(3)
        end
      end
    end

    context 'with multiple similar requests in a well' do
      let(:request_e) do
        create :library_request,
               state: 'pending',
               request_type: request_type_a,
               uuid: 'request-4',
               library_type: library_type_name_a
      end

      let(:well_a1) do
        create(:well, position: { 'name' => 'A1' }, requests_as_source: [request_a, request_e], outer_request: nil)
      end

      context 'with an invalid filter' do
        subject { described_class.new(creator: labware_creator, request_type_key: request_type_key_a) }

        it 'raises an exception' do
          expect { subject.filtered }.to raise_error(LabwareCreators::WellFilter::FilterError)

          # well a1 has two requests that match the filter
          expect(subject.errors.messages[:base].count).to eq(1)
          expect(subject.errors.messages[:base][0]).to eq('found 2 eligible requests for A1')
        end
      end
    end
  end
end
