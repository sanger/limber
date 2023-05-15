# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative '../../support/shared_tagging_examples'
require_relative 'shared_examples'

# Uses a custom transfer template to transfer material into the new plate.
# Creates and adds new control samples to the child plate.
# Adds the controls to randomised well locations on the child plate, potentially displacing samples
# that would otherwise have been stamped across.
RSpec.describe LabwareCreators::StampedPlateAddingRandomisedControls do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  has_a_working_api

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }
  let(:parent_plate_v2) do
    create :v2_stock_plate, uuid: parent_uuid, barcode_number: '2', size: plate_size, outer_requests: requests
  end
  let(:child_plate_v2) do
    create :v2_plate, uuid: 'child-uuid', barcode_number: '3', size: plate_size, outer_requests: requests
  end
  let(:requests) { Array.new(plate_size) { |i| create :library_request, state: 'started', uuid: "request-#{i}" } }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let(:parent_plate_includes) do
    'wells.requests_as_source,wells.requests_as_source.request_type,' \
      'wells.aliquots,wells.aliquots.sample,wells.aliquots.sample.sample_metadata'
  end
  let(:control_well_locations) { %w[B5 H3] }

  let(:control_study_name) { 'UAT Study' }
  let(:control_study) { create :v2_study, name: control_study_name }

  let(:control_project_name) { 'UAT Project' }
  let(:control_project) { create :v2_project, name: control_project_name }

  let(:sample_md_cohort) { 'Cohort' }
  let(:sample_md_sample_description) { 'Description' }

  let(:control_pos_sample_name) { 'CONTROL_POS_Description_B5' }
  let(:control_neg_sample_name) { 'CONTROL_NEG_Description_B5' }

  let!(:control_pos_sample_metadata) do
    create :v2_sample_metadata,
           supplier_name: control_pos_sample_name,
           cohort: sample_md_cohort,
           sample_description: sample_md_sample_description
  end

  let!(:control_neg_sample_metadata) do
    create :v2_sample_metadata,
           supplier_name: control_neg_sample_name,
           cohort: sample_md_cohort,
           sample_description: sample_md_sample_description
  end

  let(:control_sample_pos) do
    create :v2_sample,
           name: control_pos_sample_name,
           control: true,
           control_type: 'pcr positive',
           sample_metadata: control_pos_sample_metadata
  end

  let(:control_sample_neg) do
    create :v2_sample,
           name: control_neg_sample_name,
           control: true,
           control_type: 'pcr negative',
           sample_metadata: control_neg_sample_metadata
  end

  let(:child_well_pos) { child_plate_v2.wells.select { |well| well.position['name'] == control_well_locations[0] }.first }
  let(:child_well_neg) { child_plate_v2.wells.select { |well| well.position['name'] == control_well_locations[1] }.first }

  let(:control_aliquot_pos) do
    create :v2_aliquot,
           sample: control_sample_pos,
           study: control_study,
           project: control_project,
           receptacle: child_well_pos
  end

  let(:control_aliquot_neg) do
    create :v2_aliquot,
           sample: control_sample_neg,
           study: control_study,
           project: control_project,
           receptacle: child_well_neg
  end

  before do
    create(
      :stamp_with_randomised_controls_purpose_config,
      name: child_purpose_name,
      uuid: child_purpose_uuid,
      control_study_name: control_study_name
    )
    stub_v2_plate(child_plate_v2, stub_search: false, custom_query: [:plate_with_wells, child_plate_v2.uuid])
    stub_v2_plate(parent_plate_v2, stub_search: false, custom_includes: parent_plate_includes)
    stub_v2_study(control_study)
    stub_v2_project(control_project)
  end

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  subject { LabwareCreators::StampedPlateAddingRandomisedControls.new(api, form_attributes) }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a LabwareCreators::StampedPlateAddingRandomisedControls
    end
  end

  shared_examples 'a stamped plate adding randomised controls creator' do
    describe '#save!' do
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

      # NB. the order of these samples is controlled by calling them in the before on the test
      let(:api_v2_save_control_pos) { stub_api_v2_save('Sample', control_sample_pos) }
      let(:api_v2_save_control_neg) { stub_api_v2_save('Sample', control_sample_neg) }

      let!(:api_v2_post) { stub_api_v2_post('Sample') }

      let!(:api_v2_update_sample_metadata) { stub_api_v2_post('SampleMetadata') }

      # NB. the order of these aliquots is controlled by calling them in the before on the test
      let(:api_v2_save_aliquot_pos) { stub_api_v2_save('Aliquot', control_aliquot_pos) }
      let(:api_v2_save_aliquot_neg) { stub_api_v2_save('Aliquot', control_aliquot_neg) }

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

      it 'makes the expected requests' do
        expect(subject.save!).to eq true
        expect(plate_creation_request).to have_been_made
        expect(transfer_creation_request).to have_been_made
      end
    end
  end

  context '96 well plate' do
    let(:plate_size) { 96 }

    let(:transfer_requests) do
      control_locations = subject.generate_control_well_locations

      WellHelpers
        .column_order(plate_size)
        .each_with_index
        .map do |well_name, index|
          next if control_locations.include?(well_name)
          {
            'source_asset' => "2-well-#{well_name}",
            'target_asset' => "3-well-#{well_name}",
            'outer_request' => "request-#{index}"
          }
        end
        .compact
    end

    before do
      allow(subject).to receive(:generate_control_well_locations).and_return(control_well_locations)
      api_v2_save_control_pos
      api_v2_save_control_neg
      api_v2_save_aliquot_pos
      api_v2_save_aliquot_neg
    end

    it_behaves_like 'a stamped plate adding randomised controls creator'
  end

  context '384 well plate' do
    let(:plate_size) { 384 }

    let(:transfer_requests) do
      control_locations = subject.generate_control_well_locations

      WellHelpers
        .column_order(plate_size)
        .each_with_index
        .map do |well_name, index|
          next if control_locations.include?(well_name)
          {
            source_asset: "2-well-#{well_name}",
            target_asset: "3-well-#{well_name}",
            outer_request: "request-#{index}"
          }
        end
        .compact
    end

    before do
      allow(subject).to receive(:generate_control_well_locations).and_return(control_well_locations)
      api_v2_save_control_pos
      api_v2_save_control_neg
      api_v2_save_aliquot_pos
      api_v2_save_aliquot_neg
    end

    it_behaves_like 'a stamped plate adding randomised controls creator'
  end

  # context 'more complicated scenarios' do
  #   let(:plate) { create :v2_plate, uuid: parent_uuid, barcode_number: '2', wells: wells }

  #   context 'with multiple requests of different types' do
  #     let(:request_type_a) { create :request_type, key: 'rt_a' }
  #     let(:request_type_b) { create :request_type, key: 'rt_b' }
  #     let(:request_a) { create :library_request, request_type: request_type_a, uuid: 'request-a' }
  #     let(:request_b) { create :library_request, request_type: request_type_b, uuid: 'request-b' }
  #     let(:request_c) { create :library_request, request_type: request_type_a, uuid: 'request-c' }
  #     let(:request_d) { create :library_request, request_type: request_type_b, uuid: 'request-d' }
  #     let(:wells) do
  #       [
  #         create(
  #           :v2_stock_well,
  #           uuid: '2-well-A1',
  #           location: 'A1',
  #           aliquot_count: 1,
  #           requests_as_source: [request_a, request_b]
  #         ),
  #         create(
  #           :v2_stock_well,
  #           uuid: '2-well-B1',
  #           location: 'B1',
  #           aliquot_count: 1,
  #           requests_as_source: [request_c, request_d]
  #         ),
  #         create(:v2_stock_well, uuid: '2-well-c1', location: 'C1', aliquot_count: 0, requests_as_source: [])
  #       ]
  #     end
  #     let(:transfer_requests) do
  #       [
  #         { 'source_asset' => '2-well-A1', 'target_asset' => '3-well-A1', 'outer_request' => 'request-b' },
  #         { 'source_asset' => '2-well-B1', 'target_asset' => '3-well-B1', 'outer_request' => 'request-d' }
  #       ]
  #     end

  #     context 'when a request_type is supplied' do
  #       let(:form_attributes) do
  #         {
  #           purpose_uuid: child_purpose_uuid,
  #           parent_uuid: parent_uuid,
  #           user_uuid: user_uuid,
  #           filters: {
  #             request_type_key: [request_type_b.key]
  #           }
  #         }
  #       end

  #       it_behaves_like 'a stamped plate adding randomised controls creator'
  #     end

  #     context 'when a request_type is not supplied' do
  #       let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  #       it 'raises an exception' do
  #         expect { subject.save! }.to raise_error(LabwareCreators::ResourceInvalid)
  #       end
  #     end

  #     context 'when using library type filter' do
  #       let(:lib_type_a) { 'LibTypeA' }
  #       let(:request_b) do
  #         create :library_request, request_type: request_type_b, uuid: 'request-b', library_type: lib_type_a
  #       end
  #       let(:request_d) do
  #         create :library_request, request_type: request_type_b, uuid: 'request-d', library_type: lib_type_a
  #       end

  #       context 'when a library type is supplied' do
  #         let(:form_attributes) do
  #           {
  #             purpose_uuid: child_purpose_uuid,
  #             parent_uuid: parent_uuid,
  #             user_uuid: user_uuid,
  #             filters: {
  #               library_type: [lib_type_a]
  #             }
  #           }
  #         end

  #         it_behaves_like 'a stamped plate adding randomised controls creator'
  #       end

  #       context 'when both request and library types are supplied' do
  #         let(:form_attributes) do
  #           {
  #             purpose_uuid: child_purpose_uuid,
  #             parent_uuid: parent_uuid,
  #             user_uuid: user_uuid,
  #             filters: {
  #               request_type_key: [request_type_b.key],
  #               library_type: [lib_type_a]
  #             }
  #           }
  #         end

  #         it_behaves_like 'a stamped plate adding randomised controls creator'
  #       end

  #       context 'when a library type is supplied that does not match any request' do
  #         let(:form_attributes) do
  #           {
  #             purpose_uuid: child_purpose_uuid,
  #             parent_uuid: parent_uuid,
  #             user_uuid: user_uuid,
  #             filters: {
  #               library_type: ['LibTypeB']
  #             }
  #           }
  #         end

  #         it 'raises an exception' do
  #           expect { subject.save! }.to raise_error(LabwareCreators::ResourceInvalid)
  #         end
  #       end
  #     end
  #   end

  #   context 'such as the ISC pipeline post pooling' do
  #     # Here we have multiple aliquots in the source well, which all need to be transferred
  #     # We don't specify an outer request, and Sequencescape should just move the aliquots across
  #     # as normal.
  #     let(:request_type) { create :request_type, key: 'rt_a' }
  #     let(:request_a) { create :library_request, request_type: request_type, uuid: 'request-a', submission_id: '2' }
  #     let(:request_b) { create :library_request, request_type: request_type, uuid: 'request-b', submission_id: '2' }
  #     let(:request_c) { create :library_request, request_type: request_type, uuid: 'request-c', submission_id: '2' }
  #     let(:request_d) { create :library_request, request_type: request_type, uuid: 'request-d', submission_id: '2' }
  #     let(:aliquots_a) do
  #       [
  #         create(:v2_aliquot, library_state: 'started', outer_request: request_a),
  #         create(:v2_aliquot, library_state: 'started', outer_request: request_b)
  #       ]
  #     end
  #     let(:aliquots_b) do
  #       [
  #         create(:v2_aliquot, library_state: 'started', outer_request: request_c),
  #         create(:v2_aliquot, library_state: 'started', outer_request: request_d)
  #       ]
  #     end

  #     let(:wells) do
  #       [
  #         create(:v2_well, uuid: '2-well-A1', location: 'A1', aliquots: aliquots_a),
  #         create(:v2_well, uuid: '2-well-B1', location: 'B1', aliquots: aliquots_b)
  #       ]
  #     end

  #     context 'when a request_type is supplied' do
  #       let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  #       let(:transfer_requests) do
  #         [
  #           { 'source_asset' => '2-well-A1', 'target_asset' => '3-well-A1', 'submission_id' => '2' },
  #           { 'source_asset' => '2-well-B1', 'target_asset' => '3-well-B1', 'submission_id' => '2' }
  #         ]
  #       end

  #       it_behaves_like 'a stamped plate adding randomised controls creator'
  #     end
  #   end
  # end
end
