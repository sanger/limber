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
  let(:library_type_name) { 'example_library' }
  let(:submission_uuid) { 'sub-uuid' }
  let(:submission_for_cleanup_id) { '1' }
  let(:submission_for_cleanup) { create :v2_submission, id: submission_for_cleanup_id, uuid: submission_uuid }
  let(:bait_library_1) { create :bait_library, name: 'HybPanel1' }

  let(:request_a1) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-a1',
           library_type: library_type_name,
           diluent_volume: 25.0,
           pcr_cycles: 14,
           submit_for_sequencing: true,
           sub_pool: 1,
           coverage: 15,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:request_b1) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-b1',
           library_type: library_type_name,
           diluent_volume: 24.9,
           pcr_cycles: 14,
           submit_for_sequencing: true,
           sub_pool: 1,
           coverage: 15,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:request_d1) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-d1',
           library_type: library_type_name,
           diluent_volume: 24.8,
           pcr_cycles: 16,
           submit_for_sequencing: true,
           sub_pool: 2,
           coverage: 15,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:request_f1) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-f1',
           library_type: library_type_name,
           diluent_volume: 24.7,
           pcr_cycles: 12,
           submit_for_sequencing: true,
           sub_pool: 1,
           coverage: 15,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:request_h1) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-h1',
           library_type: library_type_name,
           diluent_volume: 24.6,
           pcr_cycles: 12,
           submit_for_sequencing: true,
           sub_pool: 2,
           coverage: 30,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:request_a2) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-a2',
           library_type: library_type_name,
           diluent_volume: 24.5,
           pcr_cycles: 12,
           submit_for_sequencing: true,
           sub_pool: 1,
           coverage: 15,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:request_c2) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-c2',
           library_type: library_type_name,
           diluent_volume: 24.4,
           pcr_cycles: 12,
           submit_for_sequencing: true,
           sub_pool: 2,
           coverage: 15,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:request_d2) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-d2',
           library_type: library_type_name,
           diluent_volume: 24.3,
           pcr_cycles: 12,
           submit_for_sequencing: true,
           sub_pool: 1,
           coverage: 15,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:request_g2) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-g2',
           library_type: library_type_name,
           diluent_volume: 24.2,
           pcr_cycles: 14,
           submit_for_sequencing: true,
           sub_pool: 1,
           coverage: 30,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:request_h2) do
    create :dilution_and_cleanup_request,
           state: 'pending',
           uuid: 'request-h2',
           library_type: library_type_name,
           diluent_volume: 27.353,
           pcr_cycles: 16,
           submit_for_sequencing: true,
           sub_pool: 1,
           coverage: 15,
           bait_library: bait_library_1,
           submission_id: submission_for_cleanup_id,
           submission: submission_for_cleanup
  end

  let(:example_submission_template_uuid) { SecureRandom.uuid }

  # parent
  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }

  let(:well_a1) do
    create(
      :v2_stock_well,
      location: 'A1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: request_a1
    )
  end
  let(:well_b1) do
    create(
      :v2_stock_well,
      location: 'B1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: request_b1
    )
  end
  let(:well_d1) do
    create(
      :v2_stock_well,
      location: 'D1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: request_d1
    )
  end
  let(:well_e1) do
    create(
      :v2_stock_well,
      location: 'E1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: nil
    )
  end
  let(:well_f1) do
    create(
      :v2_stock_well,
      location: 'F1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: request_f1
    )
  end
  let(:well_h1) do
    create(
      :v2_stock_well,
      location: 'H1',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: request_h1
    )
  end
  let(:well_a2) do
    create(
      :v2_stock_well,
      location: 'A2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: request_a2
    )
  end
  let(:well_b2) do
    create(
      :v2_stock_well,
      location: 'B2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: nil
    )
  end
  let(:well_c2) do
    create(
      :v2_stock_well,
      location: 'C2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: request_c2
    )
  end
  let(:well_d2) do
    create(
      :v2_stock_well,
      location: 'D2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: request_d2
    )
  end
  let(:well_e2) do
    create(
      :v2_stock_well,
      location: 'E2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: nil
    )
  end
  let(:well_f2) do
    create(
      :v2_stock_well,
      location: 'F2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: nil
    )
  end
  let(:well_g2) do
    create(
      :v2_stock_well,
      location: 'G2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: request_g2
    )
  end
  let(:well_h2) do
    create(
      :v2_stock_well,
      location: 'H2',
      qc_results: create_list(:qc_result_concentration, 1, value: 1.0),
      outer_request: request_h2
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
           ]
  end

  let(:parent_plate_v1) { json :plate, uuid: parent_uuid, stock_plate_barcode: 2, qc_files_actions: %w[read create] }

  let(:expected_skipped_wells) { %w[E1 B2 E2 F2] }

  # child
  let(:child_uuid) { 'child-uuid' }
  let(:child_v2_plate) { create :v2_plate, uuid: child_uuid, barcode_number: '3', size: plate_size }

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

    before do
      stub_get_parent_v1

      Settings.submission_templates = { 'example' => example_submission_template_uuid }

      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,' \
            'wells.aliquots.request.request_type,wells.aliquots.study'
      )

      # this child stub is for after creation of the child plate
      stub_v2_plate(child_v2_plate, stub_search: false, custom_query: [:plate_with_wells, child_v2_plate.uuid])

      # this child stub is for after transfer
      stub_v2_plate(child_v2_plate, stub_search: false, custom_includes: 'wells.aliquots')

      stub_upload_file_creation

      # set up a stub for the hyb panel field lookup (bait library)
      stub_v2_bait_library(bait_library_1.name, bait_library_1)

      allow('Sequencescape::Api::V2::Submission'.constantize).to receive(:where)
        .with(uuid: submission_uuid)
        .and_return([submission_for_cleanup])
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
            'outer_request' => request_a1.uuid
          },
          {
            'volume' => '5.1',
            'source_asset' => well_b1.uuid,
            'target_asset' => '3-well-B2',
            'outer_request' => request_b1.uuid
          },
          {
            'volume' => '5.2',
            'source_asset' => well_d1.uuid,
            'target_asset' => '3-well-A1',
            'outer_request' => request_d1.uuid
          },
          {
            'volume' => '5.3',
            'source_asset' => well_f1.uuid,
            'target_asset' => '3-well-A3',
            'outer_request' => request_f1.uuid
          },
          {
            'volume' => '5.4',
            'source_asset' => well_h1.uuid,
            'target_asset' => '3-well-B3',
            'outer_request' => request_h1.uuid
          },
          {
            'volume' => '5.5',
            'source_asset' => well_a2.uuid,
            'target_asset' => '3-well-C3',
            'outer_request' => request_a2.uuid
          },
          {
            'volume' => '5.6',
            'source_asset' => well_c2.uuid,
            'target_asset' => '3-well-D3',
            'outer_request' => request_c2.uuid
          },
          {
            'volume' => '5.7',
            'source_asset' => well_d2.uuid,
            'target_asset' => '3-well-E3',
            'outer_request' => request_d2.uuid
          },
          {
            'volume' => '5.8',
            'source_asset' => well_g2.uuid,
            'target_asset' => '3-well-C2',
            'outer_request' => request_g2.uuid
          },
          {
            'volume' => '3.621',
            'source_asset' => well_h2.uuid,
            'target_asset' => '3-well-B1',
            'outer_request' => request_h2.uuid
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

      let!(:submission_lookup) do
        stub_api_get(
          example_submission_template_uuid,
          body: json(:submission_template, uuid: example_submission_template_uuid)
        )
      end

      let!(:order_request_a1) do
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: [well_a1.uuid],
              request_options: {
                library_type: library_type_name,
                diluent_volume: 25.0,
                pcr_cycles: 14,
                submit_for_sequencing: true,
                sub_pool: 1,
                coverage: 15,
                bait_library: 'HybPanel1'
              },
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-a1-uuid"}}'
        )
      end
      let!(:order_request_b1) do
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: [well_b1.uuid],
              request_options: {
                library_type: library_type_name,
                diluent_volume: 24.9,
                pcr_cycles: 14,
                submit_for_sequencing: true,
                sub_pool: 1,
                coverage: 15,
                bait_library: 'HybPanel1'
              },
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-b1-uuid"}}'
        )
      end
      let!(:order_request_d1) do
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: [well_d1.uuid],
              request_options: {
                library_type: library_type_name,
                diluent_volume: 24.8,
                pcr_cycles: 16,
                submit_for_sequencing: true,
                sub_pool: 2,
                coverage: 15,
                bait_library: 'HybPanel1'
              },
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-d1-uuid"}}'
        )
      end
      let!(:order_request_f1) do
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: [well_f1.uuid],
              request_options: {
                library_type: library_type_name,
                diluent_volume: 24.7,
                pcr_cycles: 12,
                submit_for_sequencing: true,
                sub_pool: 1,
                coverage: 15,
                bait_library: 'HybPanel1'
              },
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-f1-uuid"}}'
        )
      end
      let!(:order_request_h1) do
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: [well_h1.uuid],
              request_options: {
                library_type: library_type_name,
                diluent_volume: 24.6,
                pcr_cycles: 12,
                submit_for_sequencing: true,
                sub_pool: 2,
                coverage: 30,
                bait_library: 'HybPanel1'
              },
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-h1-uuid"}}'
        )
      end
      let!(:order_request_a2) do
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: [well_a2.uuid],
              request_options: {
                library_type: library_type_name,
                diluent_volume: 24.5,
                pcr_cycles: 12,
                submit_for_sequencing: true,
                sub_pool: 1,
                coverage: 15,
                bait_library: 'HybPanel1'
              },
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-a2-uuid"}}'
        )
      end
      let!(:order_request_c2) do
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: [well_c2.uuid],
              request_options: {
                library_type: library_type_name,
                diluent_volume: 24.4,
                pcr_cycles: 12,
                submit_for_sequencing: true,
                sub_pool: 2,
                coverage: 15,
                bait_library: 'HybPanel1'
              },
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-c2-uuid"}}'
        )
      end
      let!(:order_request_d2) do
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: [well_d2.uuid],
              request_options: {
                library_type: library_type_name,
                diluent_volume: 24.3,
                pcr_cycles: 12,
                submit_for_sequencing: true,
                sub_pool: 1,
                coverage: 15,
                bait_library: 'HybPanel1'
              },
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-d2-uuid"}}'
        )
      end
      let!(:order_request_g2) do
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: [well_g2.uuid],
              request_options: {
                library_type: library_type_name,
                diluent_volume: 24.2,
                pcr_cycles: 14,
                submit_for_sequencing: true,
                sub_pool: 1,
                coverage: 30,
                bait_library: 'HybPanel1'
              },
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-g2-uuid"}}'
        )
      end
      let!(:order_request_h2) do
        stub_api_post(
          example_submission_template_uuid,
          'orders',
          payload: {
            order: {
              assets: [well_h2.uuid],
              request_options: {
                library_type: library_type_name,
                diluent_volume: 27.353,
                pcr_cycles: 16,
                submit_for_sequencing: true,
                sub_pool: 1,
                coverage: 15,
                bait_library: 'HybPanel1'
              },
              user: user_uuid,
              autodetect_studies_projects: true
            }
          },
          body: '{"order":{"uuid":"order-h2-uuid"}}'
        )
      end

      let(:order_ids) do
        %w[
          order-a1-uuid
          order-b1-uuid
          order-d1-uuid
          order-f1-uuid
          order-h1-uuid
          order-a2-uuid
          order-c2-uuid
          order-d2-uuid
          order-g2-uuid
          order-h2-uuid
        ]
      end

      let!(:submission_request) do
        stub_api_post(
          'submissions',
          payload: {
            submission: {
              orders: order_ids,
              user: user_uuid
            }
          },
          body: json(:submission, uuid: submission_uuid, orders: [{ uuid: order_ids }])
        )
      end

      let!(:submission_submit) { stub_api_post(submission_uuid, 'submit') }

      context 'when it is a normal valid file' do
        it 'makes the expected transfer requests to bin the wells' do
          expect(subject.save!).to eq true
          expect(subject.skipped_wells).to match(expected_skipped_wells)
          expect(plate_creation_request).to have_been_made
          expect(submission_lookup).to have_been_made.once
          expect(transfer_creation_request).to have_been_made
          expect(order_request_a1).to have_been_made.once
          expect(order_request_h2).to have_been_made.once
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

      context 'when there are different valid hyb panels' do
        let(:bait_library_2) { create :bait_library, name: 'HybPanel2' }
        let(:bait_library_3) { create :bait_library, name: 'HybPanel3' }

        let(:file) do
          fixture_file_upload(
            'spec/fixtures/files/pcr_cycles_binned_plate_dil_file_with_multiple_hyb_panels.csv',
            'sequencescape/qc_file'
          )
        end

        let!(:order_request_d1) do
          stub_api_post(
            example_submission_template_uuid,
            'orders',
            payload: {
              order: {
                assets: [well_d1.uuid],
                request_options: {
                  library_type: library_type_name,
                  diluent_volume: 24.8,
                  pcr_cycles: 16,
                  submit_for_sequencing: true,
                  sub_pool: 2,
                  coverage: 15,
                  bait_library: 'HybPanel2'
                },
                user: user_uuid,
                autodetect_studies_projects: true
              }
            },
            body: '{"order":{"uuid":"order-d1-uuid"}}'
          )
        end
        let!(:order_request_a2) do
          stub_api_post(
            example_submission_template_uuid,
            'orders',
            payload: {
              order: {
                assets: [well_a2.uuid],
                request_options: {
                  library_type: library_type_name,
                  diluent_volume: 24.5,
                  pcr_cycles: 12,
                  submit_for_sequencing: true,
                  sub_pool: 1,
                  coverage: 15,
                  bait_library: 'HybPanel2'
                },
                user: user_uuid,
                autodetect_studies_projects: true
              }
            },
            body: '{"order":{"uuid":"order-a2-uuid"}}'
          )
        end
        let!(:order_request_c2) do
          stub_api_post(
            example_submission_template_uuid,
            'orders',
            payload: {
              order: {
                assets: [well_c2.uuid],
                request_options: {
                  library_type: library_type_name,
                  diluent_volume: 24.4,
                  pcr_cycles: 12,
                  submit_for_sequencing: true,
                  sub_pool: 2,
                  coverage: 15,
                  bait_library: 'HybPanel3'
                },
                user: user_uuid,
                autodetect_studies_projects: true
              }
            },
            body: '{"order":{"uuid":"order-c2-uuid"}}'
          )
        end
        let!(:order_request_g2) do
          stub_api_post(
            example_submission_template_uuid,
            'orders',
            payload: {
              order: {
                assets: [well_g2.uuid],
                request_options: {
                  library_type: library_type_name,
                  diluent_volume: 24.2,
                  pcr_cycles: 14,
                  submit_for_sequencing: true,
                  sub_pool: 1,
                  coverage: 30,
                  bait_library: 'HybPanel3'
                },
                user: user_uuid,
                autodetect_studies_projects: true
              }
            },
            body: '{"order":{"uuid":"order-g2-uuid"}}'
          )
        end

        before do
          # set up a stub for the hyb panel field lookup (bait library)
          stub_v2_bait_library(bait_library_2.name, bait_library_2)
          stub_v2_bait_library(bait_library_3.name, bait_library_3)
        end

        it 'makes the expected transfer requests to bin the wells' do
          expect(subject.save!).to eq true
          expect(subject.skipped_wells).to match(expected_skipped_wells)
          expect(plate_creation_request).to have_been_made
          expect(submission_lookup).to have_been_made.once
          expect(transfer_creation_request).to have_been_made
          expect(order_request_a1).to have_been_made.once
          expect(order_request_h2).to have_been_made.once
          expect(submission_request).to have_been_made.once
          expect(submission_submit).to have_been_made.once
        end
      end
    end
  end
end
