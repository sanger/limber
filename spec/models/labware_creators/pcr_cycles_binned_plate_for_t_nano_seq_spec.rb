# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::PcrCyclesBinnedPlateForTNanoSeq, with: :uploader do
  subject { described_class.new(api, form_attributes) }

  it_behaves_like 'it only allows creation from plates'

  it 'has a custom page' do
    expect(described_class.page).to eq 'pcr_cycles_binned_plate_for_t_nano_seq'
  end

  let(:parent_uuid) { 'parent-plate-uuid' }
  let(:plate_size) { 96 }

  let(:parent_well_a1) do
    create(
      :v2_well,
      location: 'A1',
      position: {
        'name' => 'A1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[0]],
      outer_request: nil
    )
  end
  let(:parent_well_b1) do
    create(
      :v2_well,
      location: 'B1',
      position: {
        'name' => 'B1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[1]],
      outer_request: nil
    )
  end
  let(:parent_well_d1) do
    create(
      :v2_well,
      location: 'D1',
      position: {
        'name' => 'D1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[2]],
      outer_request: nil
    )
  end
  let(:parent_well_e1) do
    create(
      :v2_well,
      location: 'E1',
      position: {
        'name' => 'E1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[3]],
      outer_request: nil
    )
  end
  let(:parent_well_f1) do
    create(
      :v2_well,
      location: 'F1',
      position: {
        'name' => 'F1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[4]],
      outer_request: nil
    )
  end
  let(:parent_well_h1) do
    create(
      :v2_well,
      location: 'H1',
      position: {
        'name' => 'H1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[5]],
      outer_request: nil
    )
  end
  let(:parent_well_a2) do
    create(
      :v2_well,
      location: 'A2',
      position: {
        'name' => 'A2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[6]],
      outer_request: nil
    )
  end
  let(:parent_well_b2) do
    create(
      :v2_well,
      location: 'B2',
      position: {
        'name' => 'B2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[7]],
      outer_request: nil
    )
  end
  let(:parent_well_c2) do
    create(
      :v2_well,
      location: 'C2',
      position: {
        'name' => 'C2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[8]],
      outer_request: nil
    )
  end
  let(:parent_well_d2) do
    create(
      :v2_well,
      location: 'D2',
      position: {
        'name' => 'D2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[9]],
      outer_request: nil
    )
  end
  let(:parent_well_e2) do
    create(
      :v2_well,
      location: 'E2',
      position: {
        'name' => 'E2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[10]],
      outer_request: nil
    )
  end
  let(:parent_well_f2) do
    create(
      :v2_well,
      location: 'F2',
      position: {
        'name' => 'F2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[11]],
      outer_request: nil
    )
  end
  let(:parent_well_g2) do
    create(
      :v2_well,
      location: 'G2',
      position: {
        'name' => 'G2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[12]],
      outer_request: nil
    )
  end
  let(:parent_well_h2) do
    create(
      :v2_well,
      location: 'H2',
      position: {
        'name' => 'H2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [isc_prep_requests[13]],
      outer_request: nil
    )
  end

  let(:parent_plate) do
    create :v2_plate,
           uuid: parent_uuid,
           barcode_number: '2',
           size: plate_size,
           wells: [
             parent_well_a1,
             parent_well_b1,
             parent_well_d1,
             parent_well_e1,
             parent_well_f1,
             parent_well_h1,
             parent_well_a2,
             parent_well_b2,
             parent_well_c2,
             parent_well_d2,
             parent_well_e2,
             parent_well_f2,
             parent_well_g2,
             parent_well_h2
           ],
           outer_requests: isc_prep_requests
  end

  # Create child wells in order of the requests they originated from.
  # Which is to do with how the binning algorithm lays them out, based on the value of PCR cycles.
  # Just done like this to make it easier to match up the requests to the wells.
  let(:child_well_a2) do
    create(:v2_well, location: 'A2', position: { 'name' => 'A2' }, outer_request: isc_prep_requests[0])
  end
  let(:child_well_b2) do
    create(:v2_well, location: 'B2', position: { 'name' => 'B2' }, outer_request: isc_prep_requests[1])
  end
  let(:child_well_a1) do
    create(:v2_well, location: 'A1', position: { 'name' => 'A1' }, outer_request: isc_prep_requests[2])
  end
  let(:child_well_a3) do
    create(:v2_well, location: 'A3', position: { 'name' => 'A3' }, outer_request: isc_prep_requests[3])
  end
  let(:child_well_b3) do
    create(:v2_well, location: 'B3', position: { 'name' => 'B3' }, outer_request: isc_prep_requests[4])
  end
  let(:child_well_c3) do
    create(:v2_well, location: 'C3', position: { 'name' => 'C3' }, outer_request: isc_prep_requests[5])
  end
  let(:child_well_d3) do
    create(:v2_well, location: 'D3', position: { 'name' => 'D3' }, outer_request: isc_prep_requests[6])
  end
  let(:child_well_e3) do
    create(:v2_well, location: 'E3', position: { 'name' => 'E3' }, outer_request: isc_prep_requests[7])
  end
  let(:child_well_f3) do
    create(:v2_well, location: 'F3', position: { 'name' => 'F3' }, outer_request: isc_prep_requests[8])
  end
  let(:child_well_g3) do
    create(:v2_well, location: 'G3', position: { 'name' => 'G3' }, outer_request: isc_prep_requests[9])
  end
  let(:child_well_c2) do
    create(:v2_well, location: 'C2', position: { 'name' => 'C2' }, outer_request: isc_prep_requests[10])
  end
  let(:child_well_b1) do
    create(:v2_well, location: 'B1', position: { 'name' => 'B1' }, outer_request: isc_prep_requests[11])
  end
  let(:child_well_d2) do
    create(:v2_well, location: 'D2', position: { 'name' => 'D2' }, outer_request: isc_prep_requests[12])
  end
  let(:child_well_c1) do
    create(:v2_well, location: 'C1', position: { 'name' => 'C1' }, outer_request: isc_prep_requests[13])
  end

  let(:child_plate) do
    # Wells have been listed in the order here to match the order of the list of original requests.
    # Wells will be laid out by well location so this has no effect on the actual layout of the wells in the plate.
    create :v2_plate,
           uuid: 'child-uuid',
           barcode_number: '3',
           size: plate_size,
           wells: [
             child_well_a2,
             child_well_b2,
             child_well_a1,
             child_well_a3,
             child_well_b3,
             child_well_c3,
             child_well_d3,
             child_well_e3,
             child_well_f3,
             child_well_g3,
             child_well_c2,
             child_well_b1,
             child_well_d2,
             child_well_c1
           ]
  end

  let(:isc_prep_requests) { Array.new(14) { |i| create :isc_prep_request, state: 'pending', uuid: "request-#{i}" } }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let(:plate_creations_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }

  context 'on new' do
    has_a_working_api

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid } }

    it 'can be created' do
      expect(subject).to be_a described_class
    end
  end

  describe '#save' do
    has_a_working_api

    let(:form_attributes) do
      { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid, file: file }
    end

    let(:file_contents) do
      content = file.read
      file.rewind
      content
    end

    let(:qc_files_attributes) do
      [
        {
          contents: file_contents,
          filename: 'targeted_nano_seq_customer_file.csv',
          relationships: {
            labware: {
              data: {
                id: parent_plate.id,
                type: 'labware'
              }
            }
          }
        }
      ]
    end

    before do
      create :targeted_nano_seq_customer_csv_file_upload_purpose_config,
             uuid: child_purpose_uuid,
             name: child_purpose_name

      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'
      )

      # Some requests are made with standard includes, and others with the custom includes shown.
      stub_v2_plate(child_plate, stub_search: false)
      stub_v2_plate(child_plate, stub_search: false, custom_includes: 'wells.aliquots')
    end

    context 'with an invalid file' do
      let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

      it 'is false' do
        expect(subject.save).to be false
      end
    end

    # Standard expected path
    context 'when performing standard first time binning' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file.csv',
          'sequencescape/qc_file'
        )
      end

      let(:transfer_requests_attributes) do
        [
          {
            volume: '5.0',
            source_asset: parent_well_a1.uuid,
            target_asset: child_well_a2.uuid,
            outer_request: isc_prep_requests[0].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_b1.uuid,
            target_asset: child_well_b2.uuid,
            outer_request: isc_prep_requests[1].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_d1.uuid,
            target_asset: child_well_a1.uuid,
            outer_request: isc_prep_requests[2].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_e1.uuid,
            target_asset: child_well_a3.uuid,
            outer_request: isc_prep_requests[3].uuid
          },
          {
            volume: '4.0',
            source_asset: parent_well_f1.uuid,
            target_asset: child_well_b3.uuid,
            outer_request: isc_prep_requests[4].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_h1.uuid,
            target_asset: child_well_c3.uuid,
            outer_request: isc_prep_requests[5].uuid
          },
          {
            volume: '3.2',
            source_asset: parent_well_a2.uuid,
            target_asset: child_well_d3.uuid,
            outer_request: isc_prep_requests[6].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_b2.uuid,
            target_asset: child_well_e3.uuid,
            outer_request: isc_prep_requests[7].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_c2.uuid,
            target_asset: child_well_f3.uuid,
            outer_request: isc_prep_requests[8].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_d2.uuid,
            target_asset: child_well_g3.uuid,
            outer_request: isc_prep_requests[9].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_e2.uuid,
            target_asset: child_well_c2.uuid,
            outer_request: isc_prep_requests[10].uuid
          },
          {
            volume: '30.0',
            source_asset: parent_well_f2.uuid,
            target_asset: child_well_b1.uuid,
            outer_request: isc_prep_requests[11].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_g2.uuid,
            target_asset: child_well_d2.uuid,
            outer_request: isc_prep_requests[12].uuid
          },
          {
            volume: '3.621',
            source_asset: parent_well_h2.uuid,
            target_asset: child_well_c1.uuid,
            outer_request: isc_prep_requests[13].uuid
          }
        ]
      end

      before do
        stub_api_v2_patch('Well')
        stub_api_v2_save('PolyMetadatum')
      end

      it 'makes the expected method calls when creating the child plate' do
        expect_plate_creation
        expect_qc_file_creation
        expect_transfer_request_collection_creation

        # NB. because we're mocking the API call for the save of the request metadata we cannot
        # check the metadata values on the requests, only that the method was triggered.
        # Our child plate has 14 wells with 14 requests, so we expect the method to create metadata
        # on the requests to be called 14 times.
        expect(subject).to receive(:create_or_update_request_metadata).exactly(14).times

        expect(subject.save!).to be true
      end
    end

    # This context will use a file where parent wells not included in the submission are not present in the file.
    # Parent plate has 14 wells, 10 are submitted and 10 in the file. (E1, A2, C2, and G2 are omitted))
    # This should be allowed, and the child plate should be correctly created.
    context 'when the users only included submitted wells in the file' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file_with_only_submitted_rows.csv',
          'sequencescape/qc_file'
        )
      end

      # 10 sample wells in the submission, 4 sample wells to be omitted (E1, A2, C2, G2).
      let(:isc_prep_requests) { Array.new(10) { |i| create :isc_prep_request, state: 'pending', uuid: "request-#{i}" } }

      # NB. Not setting a value for requests_as_source for wells not going forward (these wells do not have
      # rows in the file)
      let(:parent_well_a1) do
        create(
          :v2_well,
          location: 'A1',
          position: {
            'name' => 'A1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[0]],
          outer_request: nil
        )
      end
      let(:parent_well_b1) do
        create(
          :v2_well,
          location: 'B1',
          position: {
            'name' => 'B1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[1]],
          outer_request: nil
        )
      end
      let(:parent_well_d1) do
        create(
          :v2_well,
          location: 'D1',
          position: {
            'name' => 'D1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[2]],
          outer_request: nil
        )
      end

      # E1 not included in Submission
      let(:parent_well_e1) do
        create(
          :v2_well,
          location: 'E1',
          position: {
            'name' => 'E1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_f1) do
        create(
          :v2_well,
          location: 'F1',
          position: {
            'name' => 'F1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[3]],
          outer_request: nil
        )
      end
      let(:parent_well_h1) do
        create(
          :v2_well,
          location: 'H1',
          position: {
            'name' => 'H1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[4]],
          outer_request: nil
        )
      end

      # A2 not included in Submission
      let(:parent_well_a2) do
        create(
          :v2_well,
          location: 'A2',
          position: {
            'name' => 'A2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_b2) do
        create(
          :v2_well,
          location: 'B2',
          position: {
            'name' => 'B2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[5]],
          outer_request: nil
        )
      end

      # C2 not included in Submission
      let(:parent_well_c2) do
        create(
          :v2_well,
          location: 'C2',
          position: {
            'name' => 'C2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_d2) do
        create(
          :v2_well,
          location: 'D2',
          position: {
            'name' => 'D2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[6]],
          outer_request: nil
        )
      end
      let(:parent_well_e2) do
        create(
          :v2_well,
          location: 'E2',
          position: {
            'name' => 'E2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[7]],
          outer_request: nil
        )
      end
      let(:parent_well_f2) do
        create(
          :v2_well,
          location: 'F2',
          position: {
            'name' => 'F2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[8]],
          outer_request: nil
        )
      end

      # G2 not included in Submission
      let(:parent_well_g2) do
        create(
          :v2_well,
          location: 'G2',
          position: {
            'name' => 'G2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_h2) do
        create(
          :v2_well,
          location: 'H2',
          position: {
            'name' => 'H2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[9]],
          outer_request: nil
        )
      end

      # Create child wells in order of the requests they originated from.
      # Which is to do with how the binning algorithm lays them out, based on the value of PCR cycles.
      # Just done like this to make it easier to match up the requests to the wells.
      let(:child_well_a2) do
        create(:v2_well, location: 'A2', position: { 'name' => 'A2' }, outer_request: isc_prep_requests[0])
      end
      let(:child_well_b2) do
        create(:v2_well, location: 'B2', position: { 'name' => 'B2' }, outer_request: isc_prep_requests[1])
      end
      let(:child_well_a1) do
        create(:v2_well, location: 'A1', position: { 'name' => 'A1' }, outer_request: isc_prep_requests[2])
      end
      let(:child_well_a3) do
        create(:v2_well, location: 'A3', position: { 'name' => 'A3' }, outer_request: isc_prep_requests[3])
      end
      let(:child_well_b3) do
        create(:v2_well, location: 'B3', position: { 'name' => 'B3' }, outer_request: isc_prep_requests[4])
      end
      let(:child_well_c3) do
        create(:v2_well, location: 'C3', position: { 'name' => 'C3' }, outer_request: isc_prep_requests[5])
      end
      let(:child_well_d3) do
        create(:v2_well, location: 'D3', position: { 'name' => 'D3' }, outer_request: isc_prep_requests[6])
      end
      let(:child_well_c2) do
        create(:v2_well, location: 'C2', position: { 'name' => 'C2' }, outer_request: isc_prep_requests[7])
      end
      let(:child_well_b1) do
        create(:v2_well, location: 'B1', position: { 'name' => 'B1' }, outer_request: isc_prep_requests[8])
      end
      let(:child_well_c1) do
        create(:v2_well, location: 'C1', position: { 'name' => 'C1' }, outer_request: isc_prep_requests[9])
      end

      let(:child_plate) do
        # Wells have been listed in the order here to match the order of the list of original requests.
        # Wells will be laid out by well location so this has no effect on the actual layout of the wells in the plate.
        create :v2_plate,
               uuid: 'child-uuid',
               barcode_number: '3',
               size: plate_size,
               wells: [
                 child_well_a2,
                 child_well_b2,
                 child_well_a1,
                 child_well_a3,
                 child_well_b3,
                 child_well_c3,
                 child_well_d3,
                 child_well_c2,
                 child_well_b1,
                 child_well_c1
               ]
      end

      # Not expecting transfer requests for ignored wells E1, A2, C2, G2
      let(:transfer_requests_attributes) do
        [
          {
            volume: '5.0',
            source_asset: parent_well_a1.uuid,
            target_asset: child_well_a2.uuid,
            outer_request: isc_prep_requests[0].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_b1.uuid,
            target_asset: child_well_b2.uuid,
            outer_request: isc_prep_requests[1].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_d1.uuid,
            target_asset: child_well_a1.uuid,
            outer_request: isc_prep_requests[2].uuid
          },
          {
            volume: '4.0',
            source_asset: parent_well_f1.uuid,
            target_asset: child_well_a3.uuid,
            outer_request: isc_prep_requests[3].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_h1.uuid,
            target_asset: child_well_b3.uuid,
            outer_request: isc_prep_requests[4].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_b2.uuid,
            target_asset: child_well_c3.uuid,
            outer_request: isc_prep_requests[5].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_d2.uuid,
            target_asset: child_well_d3.uuid,
            outer_request: isc_prep_requests[6].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_e2.uuid,
            target_asset: child_well_c2.uuid,
            outer_request: isc_prep_requests[7].uuid
          },
          {
            volume: '30.0',
            source_asset: parent_well_f2.uuid,
            target_asset: child_well_b1.uuid,
            outer_request: isc_prep_requests[8].uuid
          },
          {
            volume: '3.621',
            source_asset: parent_well_h2.uuid,
            target_asset: child_well_c1.uuid,
            outer_request: isc_prep_requests[9].uuid
          }
        ]
      end

      before do
        stub_api_v2_save('PolyMetadatum')
        stub_api_v2_post('Well')
      end

      it 'makes the expected method calls when creating the child plate' do
        expect_plate_creation
        expect_qc_file_creation
        expect_transfer_request_collection_creation

        # NB. because we're mocking the API call for the save of the request metadata we cannot
        # check the metadata values on the requests, only that the method was triggered.
        # Our child plate has 10 wells with 10 requests, so we expect the method to create metadata
        # on the requests to be called 10 times.
        expect(subject).to receive(:create_or_update_request_metadata).exactly(10).times

        expect(subject.save!).to be true
      end
    end

    # This context will use a file where some rows are set with pcr_cycles = 1.
    # These wells are not to be transferred to the child plate and should be filtered out.
    context 'when the users want to ignore a subset of the wells by setting pcr_cycles to 1' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file_with_rows_to_ignore.csv',
          'sequencescape/qc_file'
        )
      end

      # 10 sample wells in the submission, 4 sample wells to be ignored (E1, A2, C2, G2).
      let(:isc_prep_requests) { Array.new(10) { |i| create :isc_prep_request, state: 'pending', uuid: "request-#{i}" } }

      # NB. Not setting a value for requests_as_source for wells not going forward (these have pcr_cycles set to 1
      # in the customer file)
      let(:parent_well_a1) do
        create(
          :v2_well,
          location: 'A1',
          position: {
            'name' => 'A1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[0]],
          outer_request: nil
        )
      end
      let(:parent_well_b1) do
        create(
          :v2_well,
          location: 'B1',
          position: {
            'name' => 'B1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[1]],
          outer_request: nil
        )
      end
      let(:parent_well_d1) do
        create(
          :v2_well,
          location: 'D1',
          position: {
            'name' => 'D1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[2]],
          outer_request: nil
        )
      end

      # E1 not included in Submission
      let(:parent_well_e1) do
        create(
          :v2_well,
          location: 'E1',
          position: {
            'name' => 'E1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_f1) do
        create(
          :v2_well,
          location: 'F1',
          position: {
            'name' => 'F1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[3]],
          outer_request: nil
        )
      end
      let(:parent_well_h1) do
        create(
          :v2_well,
          location: 'H1',
          position: {
            'name' => 'H1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[4]],
          outer_request: nil
        )
      end

      # A2 not included in Submission
      let(:parent_well_a2) do
        create(
          :v2_well,
          location: 'A2',
          position: {
            'name' => 'A2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_b2) do
        create(
          :v2_well,
          location: 'B2',
          position: {
            'name' => 'B2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[5]],
          outer_request: nil
        )
      end

      # C2 not included in Submission
      let(:parent_well_c2) do
        create(
          :v2_well,
          location: 'C2',
          position: {
            'name' => 'C2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_d2) do
        create(
          :v2_well,
          location: 'D2',
          position: {
            'name' => 'D2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[6]],
          outer_request: nil
        )
      end
      let(:parent_well_e2) do
        create(
          :v2_well,
          location: 'E2',
          position: {
            'name' => 'E2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[7]],
          outer_request: nil
        )
      end
      let(:parent_well_f2) do
        create(
          :v2_well,
          location: 'F2',
          position: {
            'name' => 'F2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[8]],
          outer_request: nil
        )
      end

      # G2 not included in Submission
      let(:parent_well_g2) do
        create(
          :v2_well,
          location: 'G2',
          position: {
            'name' => 'G2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_h2) do
        create(
          :v2_well,
          location: 'H2',
          position: {
            'name' => 'H2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[9]],
          outer_request: nil
        )
      end

      # Create child wells in order of the requests they originated from.
      # Which is to do with how the binning algorithm lays them out, based on the value of PCR cycles.
      # Just done like this to make it easier to match up the requests to the wells.
      let(:child_well_a2) do
        create(:v2_well, location: 'A2', position: { 'name' => 'A2' }, outer_request: isc_prep_requests[0])
      end
      let(:child_well_b2) do
        create(:v2_well, location: 'B2', position: { 'name' => 'B2' }, outer_request: isc_prep_requests[1])
      end
      let(:child_well_a1) do
        create(:v2_well, location: 'A1', position: { 'name' => 'A1' }, outer_request: isc_prep_requests[2])
      end
      let(:child_well_a3) do
        create(:v2_well, location: 'A3', position: { 'name' => 'A3' }, outer_request: isc_prep_requests[3])
      end
      let(:child_well_b3) do
        create(:v2_well, location: 'B3', position: { 'name' => 'B3' }, outer_request: isc_prep_requests[4])
      end
      let(:child_well_c3) do
        create(:v2_well, location: 'C3', position: { 'name' => 'C3' }, outer_request: isc_prep_requests[5])
      end
      let(:child_well_d3) do
        create(:v2_well, location: 'D3', position: { 'name' => 'D3' }, outer_request: isc_prep_requests[6])
      end
      let(:child_well_c2) do
        create(:v2_well, location: 'C2', position: { 'name' => 'C2' }, outer_request: isc_prep_requests[7])
      end
      let(:child_well_b1) do
        create(:v2_well, location: 'B1', position: { 'name' => 'B1' }, outer_request: isc_prep_requests[8])
      end
      let(:child_well_c1) do
        create(:v2_well, location: 'C1', position: { 'name' => 'C1' }, outer_request: isc_prep_requests[9])
      end

      let(:child_plate) do
        # Wells have been listed in the order here to match the order of the list of original requests.
        # Wells will be laid out by well location so this has no effect on the actual layout of the wells in the plate.
        create :v2_plate,
               uuid: 'child-uuid',
               barcode_number: '3',
               size: plate_size,
               wells: [
                 child_well_a2,
                 child_well_b2,
                 child_well_a1,
                 child_well_a3,
                 child_well_b3,
                 child_well_c3,
                 child_well_d3,
                 child_well_c2,
                 child_well_b1,
                 child_well_c1
               ]
      end

      # Not expecting transfer requests for ignored wells E1, A2, C2, G2
      let(:transfer_requests_attributes) do
        [
          {
            volume: '5.0',
            source_asset: parent_well_a1.uuid,
            target_asset: child_well_a2.uuid,
            outer_request: isc_prep_requests[0].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_b1.uuid,
            target_asset: child_well_b2.uuid,
            outer_request: isc_prep_requests[1].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_d1.uuid,
            target_asset: child_well_a1.uuid,
            outer_request: isc_prep_requests[2].uuid
          },
          {
            volume: '4.0',
            source_asset: parent_well_f1.uuid,
            target_asset: child_well_a3.uuid,
            outer_request: isc_prep_requests[3].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_h1.uuid,
            target_asset: child_well_b3.uuid,
            outer_request: isc_prep_requests[4].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_b2.uuid,
            target_asset: child_well_c3.uuid,
            outer_request: isc_prep_requests[5].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_d2.uuid,
            target_asset: child_well_d3.uuid,
            outer_request: isc_prep_requests[6].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_e2.uuid,
            target_asset: child_well_c2.uuid,
            outer_request: isc_prep_requests[7].uuid
          },
          {
            volume: '30.0',
            source_asset: parent_well_f2.uuid,
            target_asset: child_well_b1.uuid,
            outer_request: isc_prep_requests[8].uuid
          },
          {
            volume: '3.621',
            source_asset: parent_well_h2.uuid,
            target_asset: child_well_c1.uuid,
            outer_request: isc_prep_requests[9].uuid
          }
        ]
      end

      before do
        stub_api_v2_save('PolyMetadatum')
        stub_api_v2_post('Well')
      end

      it 'makes the expected method calls when creating the child plate' do
        expect_plate_creation
        expect_qc_file_creation
        expect_transfer_request_collection_creation

        # NB. because we're mocking the API call for the save of the request metadata we cannot
        # check the metadata values on the requests, only that the method was triggered.
        # Our child plate has 10 wells with 10 requests, so we expect the method to create metadata
        # on the requests to be called 10 times.
        expect(subject).to receive(:create_or_update_request_metadata).exactly(10).times

        expect(subject.save!).to be true
      end
    end

    # This context will check the situation where the submission is missing one or more sample wells
    # that are present in the file and intended to go forward (with valid values and pcr_cycles > 1).
    # An error should be reported to the user.
    context 'when sample wells were intended to go forward in the file but missed from the submission' do
      # File contains rows for 14 wells, 4 of which are not in the submission.
      # File contains valid values for 12 rows (pcr_cycles > 1), 2 of which are missing from the submission
      # (E1 and C2), and the other 2 rows are to be ignored (have pcr_cycles = 1, A2 and G2)
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file_with_rows_missed_from_submission.csv',
          'sequencescape/qc_file'
        )
      end

      # 10 sample wells in the submission, 4 sample wells not included (E1, A2, C2, G2).
      let(:isc_prep_requests) { Array.new(10) { |i| create :isc_prep_request, state: 'pending', uuid: "request-#{i}" } }

      # 14 parent wells of which 10 are linked to requests_as_source (4 rows in file are missing requests: E1, A2, C2,
      # and G2)
      # i.e We are not setting a value for requests_as_source for wells not going forward (A2 and G2 have pcr_cycles
      # set to 1 in file).
      # And we are not setting a value for requests_as_source for wells E1 and C2, to simulate they have been missed
      # from the submission.
      let(:parent_well_a1) do
        create(
          :v2_well,
          location: 'A1',
          position: {
            'name' => 'A1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[0]],
          outer_request: nil
        )
      end
      let(:parent_well_b1) do
        create(
          :v2_well,
          location: 'B1',
          position: {
            'name' => 'B1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[1]],
          outer_request: nil
        )
      end
      let(:parent_well_d1) do
        create(
          :v2_well,
          location: 'D1',
          position: {
            'name' => 'D1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[2]],
          outer_request: nil
        )
      end

      # E1 not included in Submission
      let(:parent_well_e1) do
        create(
          :v2_well,
          location: 'E1',
          position: {
            'name' => 'E1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_f1) do
        create(
          :v2_well,
          location: 'F1',
          position: {
            'name' => 'F1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[3]],
          outer_request: nil
        )
      end
      let(:parent_well_h1) do
        create(
          :v2_well,
          location: 'H1',
          position: {
            'name' => 'H1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[4]],
          outer_request: nil
        )
      end

      # A2 not included in Submission
      let(:parent_well_a2) do
        create(
          :v2_well,
          location: 'A2',
          position: {
            'name' => 'A2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_b2) do
        create(
          :v2_well,
          location: 'B2',
          position: {
            'name' => 'B2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[5]],
          outer_request: nil
        )
      end

      # C2 not included in Submission
      let(:parent_well_c2) do
        create(
          :v2_well,
          location: 'C2',
          position: {
            'name' => 'C2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_d2) do
        create(
          :v2_well,
          location: 'D2',
          position: {
            'name' => 'D2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[6]],
          outer_request: nil
        )
      end
      let(:parent_well_e2) do
        create(
          :v2_well,
          location: 'E2',
          position: {
            'name' => 'E2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[7]],
          outer_request: nil
        )
      end
      let(:parent_well_f2) do
        create(
          :v2_well,
          location: 'F2',
          position: {
            'name' => 'F2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[8]],
          outer_request: nil
        )
      end

      # G2 not included in Submission
      let(:parent_well_g2) do
        create(
          :v2_well,
          location: 'G2',
          position: {
            'name' => 'G2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [],
          outer_request: nil
        )
      end
      let(:parent_well_h2) do
        create(
          :v2_well,
          location: 'H2',
          position: {
            'name' => 'H2'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [isc_prep_requests[9]],
          outer_request: nil
        )
      end

      let(:expected_error_message) do
        'The uploaded Customer file does not contain the same number of valid rows (12) as there are wells ' \
          'submitted for work on the parent plate (10). ' \
          'Please check the Customer file vs the Submission for missing or extra rows. ' \
          'Well E1 - File: present, Submission: missing, Well C2 - File: present, Submission: missing'
      end

      it 'reports an error' do
        expect(subject.save).to be false

        # list of missing wells should be included in the error message (E1 and C2)
        expect(subject.errors.full_messages).to include(expected_error_message)
      end
    end

    # This context will check the situation where the submission contains a sample well that is not in the file.
    # i.e. a parent well that was not intended to go forward is left out of the file on purpose but is accidently
    # included in the submission.
    context 'when a sample well appears in the submission but not in the file' do
      # File contains rows for 13 wells, but 14 are in the submission (missing row for A2)
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file_missing_submitted_well.csv',
          'sequencescape/qc_file'
        )
      end

      # this message is generated by the validation that checks for filtered wells in the file
      let(:expected_error_message_missing_row) do
        'Csv file is missing a row for well A2, all wells with content must have a row in the uploaded file.'
      end

      # this message is generated by the validation that checks the file matches the submission
      let(:expected_error_message_customer_file) do
        'The uploaded Customer file does not contain the same number of valid rows (13) as there are wells ' \
          'submitted for work on the parent plate (14). ' \
          'Please check the Customer file vs the Submission for missing or extra rows. ' \
          'Well A2 - File: missing, Submission: present'
      end

      it 'reports an error' do
        expect(subject.save).to be false
        expect(subject.errors.full_messages).to include(expected_error_message_missing_row)
        expect(subject.errors.full_messages).to include(expected_error_message_customer_file)
      end
    end

    context 'when looping back to the AL Lib plate for an additional round of ISC Prep' do
      let(:loop_1_request) { create :isc_prep_request, state: 'passed', uuid: 'request-1' }

      let(:loop_2_request) { create :isc_prep_request, state: 'pending', uuid: 'request-2' }

      let(:parent_well_a1) do
        create(
          :v2_well,
          location: 'A1',
          position: {
            'name' => 'A1'
          },
          qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
          requests_as_source: [loop_1_request, loop_2_request],
          outer_request: nil
        )
      end

      let(:parent_plate) do
        create :v2_plate,
               uuid: parent_uuid,
               barcode_number: '2',
               size: plate_size,
               wells: [parent_well_a1],
               outer_requests: [loop_1_request, loop_2_request]
      end

      # metadata for 2nd loop request
      let!(:pm_original_plate_barcode) do
        build :poly_metadatum, metadatable: loop_2_request, key: 'original_plate_barcode', value: 'DN2T'
      end
      let!(:pm_original_well_id) do
        build :poly_metadatum, metadatable: loop_2_request, key: 'original_well_id', value: 'A1'
      end
      let!(:pm_concentration_nm) do
        build :poly_metadatum, metadatable: loop_2_request, key: 'concentration_nm', value: '0.686'
      end
      let!(:pm_input_amount_available) do
        build :poly_metadatum, metadatable: loop_2_request, key: 'input_amount_available', value: '17.15'
      end
      let!(:pm_input_amount_desired) do
        build :poly_metadatum, metadatable: loop_2_request, key: 'input_amount_desired', value: '34.8'
      end
      let!(:pm_sample_volume) { build :poly_metadatum, metadatable: loop_2_request, key: 'sample_volume', value: '5.0' }
      let!(:pm_diluent_volume) do
        build :poly_metadatum, metadatable: loop_2_request, key: 'diluent_volume', value: '25.0'
      end
      let!(:pm_pcr_cycles) { build :poly_metadatum, metadatable: loop_2_request, key: 'pcr_cycles', value: '10' }
      let!(:pm_hyb_panel) { build :poly_metadatum, metadatable: loop_2_request, key: 'hyb_panel', value: 'My Panel' }

      # child
      let(:child_well_a1) do
        create(:v2_well, location: 'A1', position: { 'name' => 'A1' }, outer_request: loop_2_request)
      end

      let(:child_plate) do
        create :v2_plate, uuid: 'child-uuid', barcode_number: '3', size: plate_size, wells: [child_well_a1]
      end

      let(:transfer_requests_attributes) do
        [
          {
            volume: '5.0',
            source_asset: parent_well_a1.uuid,
            target_asset: child_well_a1.uuid,
            outer_request: loop_2_request.uuid
          }
        ]
      end

      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file_loop.csv',
          'sequencescape/qc_file'
        )
      end

      before do
        allow(pm_pcr_cycles).to receive(:update).and_return(true)

        stub_v2_polymetadata(pm_original_plate_barcode, loop_2_request.id)
        stub_v2_polymetadata(pm_original_well_id, loop_2_request.id)
        stub_v2_polymetadata(pm_concentration_nm, loop_2_request.id)
        stub_v2_polymetadata(pm_input_amount_available, loop_2_request.id)
        stub_v2_polymetadata(pm_input_amount_desired, loop_2_request.id)
        stub_v2_polymetadata(pm_sample_volume, loop_2_request.id)
        stub_v2_polymetadata(pm_diluent_volume, loop_2_request.id)
        stub_v2_polymetadata(pm_pcr_cycles, loop_2_request.id)
        stub_v2_polymetadata(pm_hyb_panel, loop_2_request.id)
      end

      it 'makes the expected method calls when creating the child plate' do
        expect_plate_creation
        expect_qc_file_creation
        expect_transfer_request_collection_creation

        # NB. because we're mocking the API call for the save of the request metadata we cannot
        # check the metadata values on the requests, only that the correct method was triggered.
        expect(subject.save!).to be true
      end

      # Check that we cannot create the child plate whilst there are active requests on the parent plate
      # from previous loops
      context 'when the request from the previous run is still active' do
        let(:loop_1_request) { create :isc_prep_request, state: 'pending', uuid: 'request-1' }

        it 'does not create the child plate' do
          expect(Sequencescape::Api::V2::PlateCreation).not_to receive(:create!)

          # WellFilter catches that there are 2 active submissions on the well and throws an exception
          expect { subject.save! }.to raise_error(LabwareCreators::ResourceInvalid)
          expect(subject.errors.messages[:well_filter].count).to eq(1)
          expect(subject.errors.messages[:well_filter][0]).to eq(
            'found 2 eligible requests for A1, possible overlapping submissions'
          )
        end
      end

      context 'when the request is not the expected type' do
        let(:loop_2_request) { create :library_request, state: 'pending', uuid: 'request-2' }

        it 'does not create the child plate' do
          expect(Sequencescape::Api::V2::PlateCreation).not_to receive(:create!)

          expect { subject.save! }.to raise_error(LabwareCreators::ResourceInvalid)
          expect(subject.errors.messages[:base].count).to eq(1)
          expect(subject.errors.messages[:base][0]).to eq(
            'Parent plate should only contain active requests of type (limber_targeted_nanoseq_isc_prep), ' \
            'found unexpected types (limber_wgs)'
          )
        end
      end
    end

    # tests for create_or_update_request_metadata method
    describe '#create_or_update_request_metadata' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file.csv',
          'sequencescape/qc_file'
        )
      end
      let(:request) { create :isc_prep_request, state: 'pending', uuid: 'request-1', id: 1 }
      let(:request_metadata) { { 'key1' => 'value1', 'key2' => 'value2' } }
      let(:child_well_location) { 'A1' }
      let!(:existing_metadata_1) { build :poly_metadatum, metadatable: request, key: 'key1', value: 'value1' }
      let!(:existing_metadata_2) { build :poly_metadatum, metadatable: request, key: 'key2', value: 'value2' }
      let(:new_metadata_1) { build :poly_metadatum, metadatable: request, key: 'key1', value: 'value1' }
      let(:new_metadata_2) { build :poly_metadatum, metadatable: request, key: 'key2', value: 'value2' }

      before do
        allow(Sequencescape::Api::V2::PolyMetadatum).to receive(:find).and_return([])
        allow(Sequencescape::Api::V2::PolyMetadatum).to receive(:new).and_return(new_metadata_1)
        allow(Sequencescape::Api::V2::PolyMetadatum).to receive(:new).and_return(new_metadata_2)
        allow(new_metadata_1).to receive(:save).and_return(true)
        allow(new_metadata_2).to receive(:save).and_return(true)
      end

      it 'creates new metadata when none exists' do
        expect(Sequencescape::Api::V2::PolyMetadatum).to receive(:new).and_return(new_metadata_1)
        expect(Sequencescape::Api::V2::PolyMetadatum).to receive(:new).and_return(new_metadata_2)
        expect(new_metadata_1).to receive(:save).once.and_return(true)
        expect(new_metadata_2).to receive(:save).once.and_return(true)
        subject.create_or_update_request_metadata(request, request_metadata, child_well_location)
      end

      it 'updates existing metadata when it exists' do
        allow(Sequencescape::Api::V2::PolyMetadatum).to receive(:find).and_return([existing_metadata_1])
        expect(existing_metadata_1).to receive(:update).once.and_return(true)
        subject.create_or_update_request_metadata(request, request_metadata, child_well_location)
      end

      it 'raises an error when new metadata fails to save' do
        allow(new_metadata_1).to receive(:save).and_return(false)
        expect do
          subject.create_or_update_request_metadata(request, request_metadata, child_well_location)
        end.to raise_error(StandardError, /did not save for request/)
      end

      it 'raises an error when existing metadata fails to update' do
        allow(Sequencescape::Api::V2::PolyMetadatum).to receive(:find).and_return([existing_metadata_1])
        allow(existing_metadata_1).to receive(:update).and_return(false)
        expect do
          subject.create_or_update_request_metadata(request, request_metadata, child_well_location)
        end.to raise_error(StandardError, /could not be updated for request/)
      end
    end
  end
end
