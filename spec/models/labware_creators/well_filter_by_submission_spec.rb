# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::WellFilterBySubmission do
  context 'when filtering wells' do
    let(:parent_uuid) { 'example-plate-uuid' }
    let(:plate_size) { 96 }

    let(:well_a1) { create(:v2_well, name: 'A1', location: 'A1', requests_as_source: [request_a], outer_request: nil) }
    let(:well_b1) { create(:v2_well, name: 'B1', location: 'B1', requests_as_source: [request_b], outer_request: nil) }
    let(:well_c1) { create(:v2_well, name: 'C1', location: 'C1', requests_as_source: [request_c], outer_request: nil) }
    let(:well_d1) { create(:v2_well, name: 'D1', location: 'D1', requests_as_source: [request_d], outer_request: nil) }

    let(:parent_plate) do
      create :v2_plate,
             uuid: parent_uuid,
             barcode_number: '2',
             size: plate_size,
             wells: [well_a1, well_b1, well_c1, well_d1],
             outer_requests: nil
    end

    let(:basic_purpose) { 'test-purpose' }
    let(:labware_creator) do
      LabwareCreators::PcrCyclesBinnedPlate.new(nil, purpose_uuid: 'test-purpose', parent_uuid: parent_uuid)
    end

    let(:request_type_key_a) { 'rt_a' }
    let(:request_type_key_b) { 'rt_b' }

    let(:request_type_a) { create :request_type, key: request_type_key_a }
    let(:request_type_b) { create :request_type, key: request_type_key_b }

    let(:library_type_name_a) { 'Library Type A' }
    let(:library_type_name_b) { 'Library Type B' }

    let(:request_state_pending) { 'pending' }

    let(:submission_1_uuid) { 'sub-1-uuid' }
    let(:submission_1_id) { '1' }
    let(:submission_1) { create :v2_submission, id: submission_1_id, uuid: submission_1_uuid }

    let(:submission_2_uuid) { 'sub-2-uuid' }
    let(:submission_2_id) { '2' }
    let(:submission_2) { create :v2_submission, id: submission_2_id, uuid: submission_2_uuid }

    let(:request_a) do
      create :library_request,
             submission_id: submission_1_id,
             state: request_state_pending,
             request_type: request_type_a,
             uuid: 'request-0',
             library_type: library_type_name_a
    end
    let(:request_b) do
      create :library_request,
             submission_id: submission_1_id,
             state: request_state_pending,
             request_type: request_type_a,
             uuid: 'request-1',
             library_type: library_type_name_a
    end
    let(:request_c) do
      create :library_request,
             submission_id: submission_2_id,
             state: request_state_pending,
             request_type: request_type_a,
             uuid: 'request-2',
             library_type: library_type_name_a
    end
    let(:request_d) do
      create :library_request,
             submission_id: submission_1_id,
             state: request_state_pending,
             request_type: request_type_a,
             uuid: 'request-3',
             library_type: library_type_name_a
    end

    before do
      create :purpose_config, uuid: basic_purpose, creator_class: 'LabwareCreators::PcrCyclesBinnedPlate'
      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,' \
            'wells.aliquots.request.request_type'
      )
    end

    context 'when a valid submission filter is applied' do
      subject { LabwareCreators::WellFilterBySubmission.new(creator: labware_creator, submission_id: 1) }

      it 'returns the correct wells' do
        expect(subject.filtered.count).to eq(3)
        expect(subject.filtered[0][0].name).to eq(well_a1.name)
        expect(subject.filtered[1][0].name).to eq(well_b1.name)
        expect(subject.filtered[2][0].name).to eq(well_d1.name)
        expect(subject.errors.messages[:base].count).to eq(0)
      end
    end

    context 'when some wells have no requests' do
      let(:well_b1) do
        create(:v2_well, name: 'B1', position: { 'name' => 'B1' }, requests_as_source: [], outer_request: nil)
      end
      let(:well_c1) do
        create(:v2_well, name: 'C1', position: { 'name' => 'C1' }, requests_as_source: [], outer_request: nil)
      end

      subject { LabwareCreators::WellFilterBySubmission.new(creator: labware_creator, submission_id: 1) }

      it 'returns the expected wells' do
        expect(subject.filtered.count).to eq(2)
        expect(subject.filtered[0][0].name).to eq(well_a1.name)
        expect(subject.filtered[1][0].name).to eq(well_d1.name)
        expect(subject.errors.messages[:base].count).to eq(0)
      end
    end

    context 'with multiple different requests in a well' do
      let(:request_e) do
        create :library_request,
               submission_id: 3,
               state: request_state_pending,
               request_type: request_type_b,
               uuid: 'request-4',
               library_type: library_type_name_b
      end

      let(:well_a1) do
        create(:v2_well, name: 'A1', location: 'A1', requests_as_source: [request_a, request_e], outer_request: nil)
      end

      context 'when a valid submission filter is applied' do
        subject { LabwareCreators::WellFilterBySubmission.new(creator: labware_creator, submission_id: 1) }

        it 'returns the expected wells' do
          expect(subject.filtered.count).to eq(3)
          expect(subject.filtered[0][0].name).to eq(well_a1.name)
          expect(subject.filtered[1][0].name).to eq(well_b1.name)
          expect(subject.filtered[2][0].name).to eq(well_d1.name)
          expect(subject.errors.messages[:base].count).to eq(0)
        end
      end

      context 'with a filter that does not match any wells' do
        subject { LabwareCreators::WellFilterBySubmission.new(creator: labware_creator, submission_id: 4) }

        # up to the creator to catch the situation where the filter returns no wells as a validation check
        it 'returns no wells' do
          expect(subject.filtered.count).to eq(0)
          expect(subject.errors.messages[:base].count).to eq(0)
        end
      end

      context 'when multiple requests in the same well match the filter' do
        let(:request_e) do
          create :library_request,
                 submission_id: 1,
                 state: request_state_pending,
                 request_type: request_type_b,
                 uuid: 'request-4',
                 library_type: library_type_name_b
        end

        let(:expected_error_msg) { 'found 2 eligible requests for A1, possible overlapping submissions' }

        subject { LabwareCreators::WellFilterBySubmission.new(creator: labware_creator, submission_id: 1) }

        # up to the creator to catch the situation where the filter returns no wells as a validation check
        it 'raises an exception' do
          expect { subject.filtered }.to raise_error(LabwareCreators::WellFilter::FilterError)

          # well a1 has two requests that match the filter
          expect(subject.errors.messages[:base].count).to eq(1)
          expect(subject.errors.messages[:base][0]).to eq(expected_error_msg)
        end
      end
    end
  end
end
