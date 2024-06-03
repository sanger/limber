# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::PcrCyclesBinnedPlateForTNanoSeq, with: :uploader do
  it_behaves_like 'it only allows creation from plates'

  subject { LabwareCreators::PcrCyclesBinnedPlateForTNanoSeq.new(api, form_attributes) }

  it 'should have a custom page' do
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

  let(:parent_plate_v1) { json :plate, uuid: parent_uuid, stock_plate_barcode: 2, qc_files_actions: %w[read create] }

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

  context 'on new' do
    has_a_working_api

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid } }

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::PcrCyclesBinnedPlateForTNanoSeq
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
      { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid, file: file }
    end

    let(:stub_upload_file_creation) do
      stub_request(:post, api_url_for(parent_uuid, 'qc_files'))
        .with(
          body: file_content,
          headers: {
            'Content-Type' => 'sequencescape/qc_file',
            'Content-Disposition' => 'form-data; filename="targeted_nano_seq_customer_file.csv"'
          }
        )
        .to_return(
          status: 201,
          body: json(:qc_file, filename: 'targeted_nano_seq_dil_file.csv'),
          headers: {
            'content-type' => 'application/json'
          }
        )
    end

    let(:stub_parent_request) { stub_api_get(parent_uuid, body: parent_plate_v1) }

    before do
      stub_parent_request

      create :targeted_nano_seq_customer_csv_file_upload_purpose_config,
             uuid: child_purpose_uuid,
             name: child_purpose_name

      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'
      )

      stub_v2_plate(child_plate, stub_search: false)
      stub_v2_plate(child_plate, stub_search: false, custom_includes: 'wells.aliquots')

      stub_upload_file_creation
    end

    context 'with an invalid file' do
      let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

      it 'is false' do
        expect(subject.save).to be false
      end
    end

    context 'when performing standard first time binning' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file.csv',
          'sequencescape/qc_file'
        )
      end

      let!(:plate_creation_request) do
        stub_api_post(
          'plate_creations',
          payload: {
            plate_creation: {
              parent: parent_uuid,
              child_purpose: child_purpose_uuid,
              user: user_uuid
            }
          },
          body: json(:plate_creation)
        )
      end

      let!(:api_v2_post) { stub_api_v2_post('Well') }

      let!(:api_v2_post) { stub_api_v2_save('PolyMetadatum') }

      let(:transfer_requests) do
        [
          {
            'volume' => '5.0',
            'source_asset' => parent_well_a1.uuid,
            'target_asset' => child_well_a2.uuid,
            'outer_request' => isc_prep_requests[0].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => parent_well_b1.uuid,
            'target_asset' => child_well_b2.uuid,
            'outer_request' => isc_prep_requests[1].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => parent_well_d1.uuid,
            'target_asset' => child_well_a1.uuid,
            'outer_request' => isc_prep_requests[2].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => parent_well_e1.uuid,
            'target_asset' => child_well_a3.uuid,
            'outer_request' => isc_prep_requests[3].uuid
          },
          {
            'volume' => '4.0',
            'source_asset' => parent_well_f1.uuid,
            'target_asset' => child_well_b3.uuid,
            'outer_request' => isc_prep_requests[4].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => parent_well_h1.uuid,
            'target_asset' => child_well_c3.uuid,
            'outer_request' => isc_prep_requests[5].uuid
          },
          {
            'volume' => '3.2',
            'source_asset' => parent_well_a2.uuid,
            'target_asset' => child_well_d3.uuid,
            'outer_request' => isc_prep_requests[6].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => parent_well_b2.uuid,
            'target_asset' => child_well_e3.uuid,
            'outer_request' => isc_prep_requests[7].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => parent_well_c2.uuid,
            'target_asset' => child_well_f3.uuid,
            'outer_request' => isc_prep_requests[8].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => parent_well_d2.uuid,
            'target_asset' => child_well_g3.uuid,
            'outer_request' => isc_prep_requests[9].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => parent_well_e2.uuid,
            'target_asset' => child_well_c2.uuid,
            'outer_request' => isc_prep_requests[10].uuid
          },
          {
            'volume' => '30.0',
            'source_asset' => parent_well_f2.uuid,
            'target_asset' => child_well_b1.uuid,
            'outer_request' => isc_prep_requests[11].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => parent_well_g2.uuid,
            'target_asset' => child_well_d2.uuid,
            'outer_request' => isc_prep_requests[12].uuid
          },
          {
            'volume' => '3.621',
            'source_asset' => parent_well_h2.uuid,
            'target_asset' => child_well_c1.uuid,
            'outer_request' => isc_prep_requests[13].uuid
          }
        ]
      end

      let!(:transfer_creation_request) do
        stub_api_post(
          'transfer_request_collections',
          payload: {
            transfer_request_collection: {
              user: user_uuid,
              transfer_requests: transfer_requests
            }
          },
          body: '{}'
        )
      end

      it 'makes the expected method calls when creating the child plate' do
        # NB. because we're mocking the API call for the save of the request metadata we cannot
        # check the metadata values on the requests, only that the method was triggered.
        # Our child plate has 14 wells with 14 requests, so we expect the method to create metadata
        # on the requests to be called 14 times.
        expect(subject).to receive(:create_or_update_request_metadata).exactly(14).times
        expect(subject.save!).to eq true
        expect(plate_creation_request).to have_been_made
        expect(transfer_creation_request).to have_been_made
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

      let(:transfer_requests) do
        [
          {
            'volume' => '5.0',
            'source_asset' => parent_well_a1.uuid,
            'target_asset' => child_well_a1.uuid,
            'outer_request' => loop_2_request.uuid
          }
        ]
      end

      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file_loop.csv',
          'sequencescape/qc_file'
        )
      end

      let!(:plate_creation_request) do
        stub_api_post(
          'plate_creations',
          payload: {
            plate_creation: {
              parent: parent_uuid,
              child_purpose: child_purpose_uuid,
              user: user_uuid
            }
          },
          body: json(:plate_creation)
        )
      end

      let!(:transfer_creation_request) do
        stub_api_post(
          'transfer_request_collections',
          payload: {
            transfer_request_collection: {
              user: user_uuid,
              transfer_requests: transfer_requests
            }
          },
          body: '{}'
        )
      end

      let!(:api_v2_post) { allow(pm_pcr_cycles).to receive(:update).and_return(true) }

      before do
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
        # NB. because we're mocking the API call for the save of the request metadata we cannot
        # check the metadata values on the requests, only that the correct method was triggered.
        expect(subject.save!).to eq true
        expect(plate_creation_request).to have_been_made
        expect(transfer_creation_request).to have_been_made
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
