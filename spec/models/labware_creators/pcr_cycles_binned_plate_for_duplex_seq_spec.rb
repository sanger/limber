# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::PcrCyclesBinnedPlateForDuplexSeq, with: :uploader do
  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from plates'

  it 'has a custom page' do
    expect(described_class.page).to eq 'pcr_cycles_binned_plate'
  end

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }

  let(:parent_well_a1) do
    create(
      :well,
      position: {
        'name' => 'A1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[0]],
      outer_request: nil
    )
  end
  let(:parent_well_b1) do
    create(
      :well,
      position: {
        'name' => 'B1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[1]],
      outer_request: nil
    )
  end
  let(:parent_well_d1) do
    create(
      :well,
      position: {
        'name' => 'D1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[2]],
      outer_request: nil
    )
  end
  let(:parent_well_e1) do
    create(
      :well,
      position: {
        'name' => 'E1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[3]],
      outer_request: nil
    )
  end
  let(:parent_well_f1) do
    create(
      :well,
      position: {
        'name' => 'F1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[4]],
      outer_request: nil
    )
  end
  let(:parent_well_h1) do
    create(
      :well,
      position: {
        'name' => 'H1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[5]],
      outer_request: nil
    )
  end
  let(:parent_well_a2) do
    create(
      :well,
      position: {
        'name' => 'A2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[6]],
      outer_request: nil
    )
  end
  let(:parent_well_b2) do
    create(
      :well,
      position: {
        'name' => 'B2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[7]],
      outer_request: nil
    )
  end
  let(:parent_well_c2) do
    create(
      :well,
      position: {
        'name' => 'C2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[8]],
      outer_request: nil
    )
  end
  let(:parent_well_d2) do
    create(
      :well,
      position: {
        'name' => 'D2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[9]],
      outer_request: nil
    )
  end
  let(:parent_well_e2) do
    create(
      :well,
      position: {
        'name' => 'E2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[10]],
      outer_request: nil
    )
  end
  let(:parent_well_f2) do
    create(
      :well,
      position: {
        'name' => 'F2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[11]],
      outer_request: nil
    )
  end
  let(:parent_well_g2) do
    create(
      :well,
      position: {
        'name' => 'G2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[12]],
      outer_request: nil
    )
  end
  let(:parent_well_h2) do
    create(
      :well,
      position: {
        'name' => 'H2'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests[13]],
      outer_request: nil
    )
  end

  let(:parent_plate) do
    create :plate,
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
           outer_requests: requests
  end

  # Create child wells in order of the requests they originated from.
  # Which is to do with how the binning algorithm lays them out based on the value of PCR cycles.
  let(:child_well_A2) { create(:well, location: 'A2', position: { 'name' => 'A2' }, outer_request: requests[0]) }
  let(:child_well_B2) { create(:well, location: 'B2', position: { 'name' => 'B2' }, outer_request: requests[1]) }
  let(:child_well_A1) { create(:well, location: 'A1', position: { 'name' => 'A1' }, outer_request: requests[2]) }
  let(:child_well_A3) { create(:well, location: 'A3', position: { 'name' => 'A3' }, outer_request: requests[3]) }
  let(:child_well_B3) { create(:well, location: 'B3', position: { 'name' => 'B3' }, outer_request: requests[4]) }
  let(:child_well_C3) { create(:well, location: 'C3', position: { 'name' => 'C3' }, outer_request: requests[5]) }
  let(:child_well_D3) { create(:well, location: 'D3', position: { 'name' => 'D3' }, outer_request: requests[6]) }
  let(:child_well_E3) { create(:well, location: 'E3', position: { 'name' => 'E3' }, outer_request: requests[7]) }
  let(:child_well_F3) { create(:well, location: 'F3', position: { 'name' => 'F3' }, outer_request: requests[8]) }
  let(:child_well_G3) { create(:well, location: 'G3', position: { 'name' => 'G3' }, outer_request: requests[9]) }
  let(:child_well_C2) { create(:well, location: 'C2', position: { 'name' => 'C2' }, outer_request: requests[10]) }
  let(:child_well_B1) { create(:well, location: 'B1', position: { 'name' => 'B1' }, outer_request: requests[11]) }
  let(:child_well_D2) { create(:well, location: 'D2', position: { 'name' => 'D2' }, outer_request: requests[12]) }
  let(:child_well_C1) { create(:well, location: 'C1', position: { 'name' => 'C1' }, outer_request: requests[13]) }

  let(:child_plate) do
    # Wells listed in the order here to match the order of the list of original library requests,
    # i.e. the rearranged order after binning. Wells will be laid out by location so this has no
    # effect on the actual layout of the plate.
    create :plate,
           uuid: 'child-uuid',
           barcode_number: '3',
           size: plate_size,
           wells: [
             child_well_A2,
             child_well_B2,
             child_well_A1,
             child_well_A3,
             child_well_B3,
             child_well_C3,
             child_well_D3,
             child_well_E3,
             child_well_F3,
             child_well_G3,
             child_well_C2,
             child_well_B1,
             child_well_D2,
             child_well_C1
           ]
  end

  let(:library_type_name) { 'Test Library Type' }

  let(:requests) do
    Array.new(14) do |i|
      create :library_request, state: 'pending', uuid: "request-#{i}", library_type: library_type_name
    end
  end

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  context 'on new' do
    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid } }

    it 'can be created' do
      expect(subject).to be_a described_class
    end
  end

  describe '#save' do
    let(:form_attributes) do
      { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid, file: file }
    end

    before do
      create(
        :duplex_seq_customer_csv_file_upload_purpose_config,
        uuid: child_purpose_uuid,
        name: child_purpose_name,
        library_type_name: library_type_name
      )

      stub_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'
      )

      # Some requests are made with standard includes, and others with the custom includes shown.
      stub_plate(child_plate, stub_search: false)
      stub_plate(child_plate, stub_search: false, custom_includes: 'wells.aliquots')
    end

    context 'with an invalid file' do
      let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

      it 'is false' do
        expect(subject.save).to be false
      end
    end

    context 'binning' do
      let(:file) do
        fixture_file_upload('spec/fixtures/files/duplex_seq/duplex_seq_dil_file.csv', 'sequencescape/qc_file')
      end

      let(:file_contents) do
        content = file.read
        file.rewind
        content
      end

      let(:plate_creations_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }

      let(:qc_files_attributes) do
        [
          {
            contents: file_contents,
            filename: 'duplex_seq_customer_file.csv',
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

      let(:transfer_requests_attributes) do
        [
          {
            volume: '5.0',
            source_asset: parent_well_a1.uuid,
            target_asset: child_well_A2.uuid,
            outer_request: requests[0].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_b1.uuid,
            target_asset: child_well_B2.uuid,
            outer_request: requests[1].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_d1.uuid,
            target_asset: child_well_A1.uuid,
            outer_request: requests[2].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_e1.uuid,
            target_asset: child_well_A3.uuid,
            outer_request: requests[3].uuid
          },
          {
            volume: '4.0',
            source_asset: parent_well_f1.uuid,
            target_asset: child_well_B3.uuid,
            outer_request: requests[4].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_h1.uuid,
            target_asset: child_well_C3.uuid,
            outer_request: requests[5].uuid
          },
          {
            volume: '3.2',
            source_asset: parent_well_a2.uuid,
            target_asset: child_well_D3.uuid,
            outer_request: requests[6].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_b2.uuid,
            target_asset: child_well_E3.uuid,
            outer_request: requests[7].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_c2.uuid,
            target_asset: child_well_F3.uuid,
            outer_request: requests[8].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_d2.uuid,
            target_asset: child_well_G3.uuid,
            outer_request: requests[9].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_e2.uuid,
            target_asset: child_well_C2.uuid,
            outer_request: requests[10].uuid
          },
          {
            volume: '30.0',
            source_asset: parent_well_f2.uuid,
            target_asset: child_well_B1.uuid,
            outer_request: requests[11].uuid
          },
          {
            volume: '5.0',
            source_asset: parent_well_g2.uuid,
            target_asset: child_well_D2.uuid,
            outer_request: requests[12].uuid
          },
          {
            volume: '3.621',
            source_asset: parent_well_h2.uuid,
            target_asset: child_well_C1.uuid,
            outer_request: requests[13].uuid
          }
        ]
      end

      before { stub_patch('Well') }

      it 'makes the expected transfer requests to bin the wells' do
        expect_plate_creation
        expect_qc_file_creation
        expect_transfer_request_collection_creation

        expect(subject.save!).to be true
      end
    end
  end
end
