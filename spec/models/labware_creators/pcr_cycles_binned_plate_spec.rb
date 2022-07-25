# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::PcrCyclesBinnedPlate, with: :uploader do
  it_behaves_like 'it only allows creation from plates'

  subject { LabwareCreators::PcrCyclesBinnedPlate.new(api, form_attributes) }

  it 'should have a custom page' do
    expect(described_class.page).to eq 'pcr_cycles_binned_plate'
  end

  # user
  let(:user_uuid) { 'user-uuid' }

  # dilution cleanup submission setup
  let(:library_type_name) { 'Test Library Type' }
  let(:submission_uuid) { 'sub-uuid' }
  let(:submission_for_cleanup_id) { '1' }
  let(:submission_for_cleanup) do
    create :v2_submission,
    id: submission_for_cleanup_id,
    uuid: submission_uuid
  end

  let(:requests_for_cleanup) do
    Array.new(10) do |i|
      create :library_request,
      state: 'pending',
      uuid: "request-#{i}",
      library_type: library_type_name,
      submission_id: submission_for_cleanup_id,
      submission: submission_for_cleanup
    end
  end

  let(:example_submission_template_uuid) { SecureRandom.uuid }

  # parent
  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }

  let(:well_a1) do
    create(
      :v2_well,
      location: 'A1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests_for_cleanup[0]],
      outer_request: nil
    )
  end
  let(:well_b1) do
    create(
      :v2_well,
      location: 'B1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests_for_cleanup[1]],
      outer_request: nil
    )
  end
  let(:well_d1) do
    create(
      :v2_well,
      location: 'D1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests_for_cleanup[2]],
      outer_request: nil
    )
  end
  let(:well_e1) do
    create(
      :v2_well,
      location: 'E1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [],
      outer_request: nil
    )
  end
  let(:well_f1) do
    create(
      :v2_well,
      location: 'F1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests_for_cleanup[3]],
      outer_request: nil
    )
  end
  let(:well_h1) do
    create(
      :v2_well,
      location: 'H1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests_for_cleanup[4]],
      outer_request: nil
    )
  end
  let(:well_a2) do
    create(
      :v2_well,
      location: 'A2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests_for_cleanup[5]],
      outer_request: nil
    )
  end
  let(:well_b2) do
    create(
      :v2_well,
      location: 'B2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [],
      outer_request: nil
    )
  end
  let(:well_c2) do
    create(
      :v2_well,
      location: 'C2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests_for_cleanup[6]],
      outer_request: nil
    )
  end
  let(:well_d2) do
    create(
      :v2_well,
      location: 'D2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests_for_cleanup[7]],
      outer_request: nil
    )
  end
  let(:well_e2) do
    create(
      :v2_well,
      location: 'E2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [],
      outer_request: nil
    )
  end
  let(:well_f2) do
    create(
      :v2_well,
      location: 'F2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [],
      outer_request: nil
    )
  end
  let(:well_g2) do
    create(
      :v2_well,
      location: 'G2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests_for_cleanup[8]],
      outer_request: nil
    )
  end
  let(:well_h2) do
    create(
      :v2_well,
      location: 'H2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      requests_as_source: [requests_for_cleanup[9]],
      outer_request: nil
    )
  end

  let(:parent_plate) do
    create :v2_plate,
           uuid: parent_uuid,
           barcode_number: '2',
           size: plate_size,
           wells: [
             well_a1,
             well_b1,
             well_d1,
             well_e1,
             well_f1,
             well_h1,
             well_a2,
             well_b2,
             well_c2,
             well_d2,
             well_e2,
             well_f2,
             well_g2,
             well_h2
           ],
           outer_requests: requests_for_cleanup
  end

  let(:parent_plate_v1) do
    json :plate,
    uuid: parent_uuid,
    stock_plate_barcode: 2,
    qc_files_actions: %w[read create]
  end

  let(:expected_skipped_wells) { %w[E1 B2 E2 F2] }
  let(:filtered_parent_asset_uuids) do
    parent_plate.wells.filter_map do |well|
      well.uuid unless expected_skipped_wells.include?(well.position['name'])
    end
  end

  # child
  let(:child_uuid) { 'child-uuid' }
  let(:child_v2_plate) do
    create :v2_plate,
    uuid: child_uuid,
    barcode_number: '3',
    size: plate_size,
    outer_requests: requests_for_cleanup
  end

  # purpose config
  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }
  let!(:purpose_config) do
    create :pcr_cycles_binned_plate_purpose_config, name: child_purpose_name, uuid: child_purpose_uuid
  end

  context 'on new' do
    has_a_working_api

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid } }

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
      { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid, file: file }
    end

    let(:stub_upload_file_creation) do
      stub_request(:post, api_url_for(parent_uuid, 'qc_files'))
        .with(
          body: file_content,
          headers: {
            'Content-Type' => 'sequencescape/qc_file',
            'Content-Disposition' => 'form-data; filename="pcr_cycles_binned_plate_customer_file.csv"'
          }
        )
        .to_return(
          status: 201,
          body: json(:qc_file, filename: 'pcr_cycles_binned_plate_dil_file.csv'),
          headers: {
            'content-type' => 'application/json'
          }
        )
    end

    let(:stub_get_parent_v1) { stub_api_get(parent_uuid, body: parent_plate_v1) }

    let(:bait_library) { create :bait_library, name: 'HybPanel1' }

    before do
      stub_get_parent_v1

      Settings.submission_templates = { 'example' => example_submission_template_uuid }

      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,'\
          'wells.aliquots.request.request_type,wells.aliquots.study'
      )
      # this child stub is for after creation of the child plate
      stub_v2_plate(child_v2_plate, stub_search: false, custom_query: [:plate_with_wells, child_v2_plate.uuid])

      # this child stub is for after transfer
      stub_v2_plate(child_v2_plate, stub_search: false, custom_includes: 'wells.aliquots')

      stub_upload_file_creation

      # set up a stub for the hyb panel field lookup (bait library)
      stub_v2_bait_library(bait_library.name, bait_library)

      allow('Sequencescape::Api::V2::Submission'.constantize).to receive(:where).with(uuid: submission_uuid).and_return(
        [submission_for_cleanup]
      )
    end

    context 'with an invalid file' do
      let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

      it 'is false' do
        expect(subject.save).to be false
      end
    end

    context 'binning' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/pcr_cycles_binned_plate_dil_file_with_zero_sample_volumes.csv',
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

      let(:transfer_requests) do
        [
          {
            'volume' => '5.0',
            'source_asset' => well_a1.uuid,
            'target_asset' => '3-well-A2',
            'outer_request' => requests_for_cleanup[0].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_b1.uuid,
            'target_asset' => '3-well-B2',
            'outer_request' => requests_for_cleanup[1].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_d1.uuid,
            'target_asset' => '3-well-A1',
            'outer_request' => requests_for_cleanup[2].uuid
          },
          {
            'volume' => '4.0',
            'source_asset' => well_f1.uuid,
            'target_asset' => '3-well-A3',
            'outer_request' => requests_for_cleanup[3].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_h1.uuid,
            'target_asset' => '3-well-B3',
            'outer_request' => requests_for_cleanup[4].uuid
          },
          {
            'volume' => '3.2',
            'source_asset' => well_a2.uuid,
            'target_asset' => '3-well-C3',
            'outer_request' => requests_for_cleanup[5].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_c2.uuid,
            'target_asset' => '3-well-D3',
            'outer_request' => requests_for_cleanup[6].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_d2.uuid,
            'target_asset' => '3-well-E3',
            'outer_request' => requests_for_cleanup[7].uuid
          },
          {
            'volume' => '5.0',
            'source_asset' => well_g2.uuid,
            'target_asset' => '3-well-C2',
            'outer_request' => requests_for_cleanup[8].uuid
          },
          {
            'volume' => '3.621',
            'source_asset' => well_h2.uuid,
            'target_asset' => '3-well-B1',
            'outer_request' => requests_for_cleanup[9].uuid
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

      let!(:order_request) do
        stub_api_get(example_submission_template_uuid,
          body: json(:submission_template, uuid: example_submission_template_uuid)
        )
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: filtered_parent_asset_uuids,
              request_options: purpose_config[:submission_options]['Test Dilution and Cleanup']['request_options'],
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-uuid"}}'
        )
      end

      let(:order_id) { 'order-uuid' }

      let!(:submission_request) do
        stub_api_post(
          'submissions',
          payload: {
            submission: {
              orders: [order_id],
              user: user_uuid
            }
          },
          body: json(:submission, uuid: submission_uuid, orders: [{ uuid: order_id }])
        )
      end

      let!(:submission_submit) { stub_api_post(submission_uuid, 'submit') }

      context 'when it is a normal valid file' do
        it 'makes the expected transfer requests to bin the wells' do
          expect(subject.save!).to eq true
          expect(subject.skipped_wells).to match(expected_skipped_wells)
          expect(plate_creation_request).to have_been_made
          expect(transfer_creation_request).to have_been_made
          expect(order_request).to have_been_made.once
          expect(submission_request).to have_been_made.once
          expect(submission_submit).to have_been_made.once
        end
      end

      context 'when the user has set all the samples to zero' do
        let(:file) do
          fixture_file_upload(
            'spec/fixtures/files/pcr_cycles_binned_plate_dil_file_with_all_zero_sample_volumes.csv',
            'sequencescape/qc_file'
          )
        end

        it 'raises an exception' do
          expect { subject.save! }.to raise_error(LabwareCreators::ResourceInvalid)
          expect(subject.errors.messages[:csv_file][0]).to eq(
            'has no well rows suitable for transfer (check sample volumes)'
          )
        end
      end
    end
  end
end
