# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::PcrCyclesBinnedPlate, with: :uploader do
  it_behaves_like 'it only allows creation from plates'

  subject do
    LabwareCreators::PcrCyclesBinnedPlate.new(api, form_attributes)
  end

  it 'should have a custom page' do
    expect(described_class.page).to eq 'pcr_cycles_binned_plate'
  end

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }

  let(:well_a1) do
    create(:v2_well,
           position: { 'name' => 'A1' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[0]],
           outer_request: nil)
  end
  let(:well_b1) do
    create(:v2_well,
           position: { 'name' => 'B1' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[1]],
           outer_request: nil)
  end
  let(:well_d1) do
    create(:v2_well,
           position: { 'name' => 'D1' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[2]],
           outer_request: nil)
  end
  let(:well_e1) do
    create(:v2_well,
           position: { 'name' => 'E1' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[3]],
           outer_request: nil)
  end
  let(:well_f1) do
    create(:v2_well,
           position: { 'name' => 'F1' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[4]],
           outer_request: nil)
  end
  let(:well_h1) do
    create(:v2_well,
           position: { 'name' => 'H1' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[5]],
           outer_request: nil)
  end
  let(:well_a2) do
    create(:v2_well,
           position: { 'name' => 'A2' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[6]],
           outer_request: nil)
  end
  let(:well_b2) do
    create(:v2_well,
           position: { 'name' => 'B2' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[7]],
           outer_request: nil)
  end
  let(:well_c2) do
    create(:v2_well,
           position: { 'name' => 'C2' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[8]],
           outer_request: nil)
  end
  let(:well_d2) do
    create(:v2_well,
           position: { 'name' => 'D2' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[9]],
           outer_request: nil)
  end
  let(:well_e2) do
    create(:v2_well,
           position: { 'name' => 'E2' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[10]],
           outer_request: nil)
  end
  let(:well_f2) do
    create(:v2_well,
           position: { 'name' => 'F2' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[11]],
           outer_request: nil)
  end
  let(:well_g2) do
    create(:v2_well,
           position: { 'name' => 'G2' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[12]],
           outer_request: nil)
  end
  let(:well_h2) do
    create(:v2_well,
           position: { 'name' => 'H2' },
           qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
           requests_as_source: [requests[13]],
           outer_request: nil)
  end

  let(:parent_plate) do
    create :v2_plate,
           uuid: parent_uuid,
           barcode_number: '2',
           size: plate_size,
           wells: [
             well_a1, well_b1, well_d1, well_e1, well_f1, well_h1, well_a2,
             well_b2, well_c2, well_d2, well_e2, well_f2, well_g2, well_h2
           ],
           outer_requests: requests
  end

  let(:parent_plate_v1) { json :plate, uuid: parent_uuid, stock_plate_barcode: 2, qc_files_actions: %w[read create] }

  let(:child_uuid) { 'child-uuid' }

  let(:child_plate) do
    create :v2_plate,
           uuid: child_uuid,
           barcode_number: '3',
           size: plate_size,
           outer_requests: requests
  end

  let(:child_plate_v1) { json :plate, uuid: child_uuid }

  let(:library_type_name) { 'Test Library Type' }

  let(:requests) { Array.new(14) { |i| create :library_request, state: 'pending', uuid: "request-#{i}", library_type: library_type_name } }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  context 'on new' do
    has_a_working_api

    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent_uuid
      }
    end

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::PcrCyclesBinnedPlate
    end
  end

  context '#save' do
    has_a_working_api

    let(:file_content) do
      content = file.read
      file.rewind
      content
    end

    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent_uuid,
        user_uuid: user_uuid,
        file: file
      }
    end

    let(:stub_upload_file_creation) do
      stub_request(:post, api_url_for(parent_uuid, 'qc_files'))
        .with(
          body: file_content,
          headers: {
            'Content-Type' => 'sequencescape/qc_file',
            'Content-Disposition' => 'form-data; filename="duplex_seq_customer_file.csv"'
          }
        ).to_return(
          status: 201,
          body: json(:qc_file, filename: 'duplex_seq_dil_file.csv'),
          headers: { 'content-type' => 'application/json' }
        )
    end

    let(:stub_parent_request) do
      stub_api_get(parent_uuid, body: parent_plate_v1)
    end

    let(:stub_child_request) do
      stub_api_get(child_uuid, body: child_plate_v1)
    end

    before do
      stub_parent_request
      # stub_child_request

      create :duplex_seq_customer_csv_file_upload_purpose_config,
             uuid: child_purpose_uuid,
             name: child_purpose_name,
             library_type_name: library_type_name

      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes: 'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'
      )

      stub_v2_plate(
        child_plate,
        stub_search: false
      )

      stub_v2_plate(
        child_plate,
        stub_search: false,
        custom_includes: 'wells.aliquots'
      )

      # stub_api_v2_post(
      #   'Well',
      #   {}
      # )

      stub_upload_file_creation
    end

    context 'with an invalid file' do
      let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

      it 'is false' do
        expect(subject.save).to be false
      end
    end

    context 'binning' do
      let(:file) { fixture_file_upload('spec/fixtures/files/duplex_seq_dil_file.csv', 'sequencescape/qc_file') }

      let!(:plate_creation_request) do
        stub_api_post('plate_creations',
                      payload: { plate_creation: {
                        parent: parent_uuid,
                        child_purpose: child_purpose_uuid,
                        user: user_uuid
                      } },
                      body: json(:plate_creation))
      end

      let(:transfer_requests) do
        [
          {
            'volume' => '5.0',
            'source_asset' => well_a1.uuid,
            'target_asset' => '3-well-A2',
            'outer_request' => requests[0].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_b1.uuid,
            'target_asset' => '3-well-B2',
            'outer_request' => requests[1].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_d1.uuid,
            'target_asset' => '3-well-A1',
            'outer_request' => requests[2].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_e1.uuid,
            'target_asset' => '3-well-A3',
            'outer_request' => requests[3].uuid
          },
          {
            'volume' => '4.0',
            'source_asset' => well_f1.uuid,
            'target_asset' => '3-well-B3',
            'outer_request' => requests[4].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_h1.uuid,
            'target_asset' => '3-well-C3',
            'outer_request' => requests[5].uuid
          },
          {
            'volume' => '3.2',
            'source_asset' => well_a2.uuid,
            'target_asset' => '3-well-D3',
            'outer_request' => requests[6].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_b2.uuid,
            'target_asset' => '3-well-E3',
            'outer_request' => requests[7].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_c2.uuid,
            'target_asset' => '3-well-F3',
            'outer_request' => requests[8].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_d2.uuid,
            'target_asset' => '3-well-G3',
            'outer_request' => requests[9].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_e2.uuid,
            'target_asset' => '3-well-C2',
            'outer_request' => requests[10].uuid
          },
          {
            'volume' => '30.0',
            'source_asset' => well_f2.uuid,
            'target_asset' => '3-well-B1',
            'outer_request' => requests[11].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_g2.uuid,
            'target_asset' => '3-well-D2',
            'outer_request' => requests[12].uuid
          },
          {
            'volume' => '3.621',
            'source_asset' => well_h2.uuid,
            'target_asset' => '3-well-C1',
            'outer_request' => requests[13].uuid
          }
        ]
      end

      let!(:transfer_creation_request) do
        stub_api_post('transfer_request_collections',
                      payload: { transfer_request_collection: {
                        user: user_uuid,
                        transfer_requests: transfer_requests
                      } },
                      body: '{}')
      end

      it 'makes the expected transfer requests to bin the wells' do
        expect(subject.save!).to eq true
        expect(plate_creation_request).to have_been_made
        expect(transfer_creation_request).to have_been_made
      end

      it 'makes the expected request to save information to the wells' do
        expect(subject.save!).to eq true
      end
    end
  end
end
