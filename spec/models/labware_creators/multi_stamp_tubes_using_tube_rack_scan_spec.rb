# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

# # Up to 96 tubes are transferred onto a single 96-well plate.
RSpec.describe LabwareCreators::MultiStampTubesUsingTubeRackScan, with: :uploader do
  it_behaves_like 'it only allows creation from tubes'

  has_a_working_api

  # samples
  let(:sample1_uuid) { SecureRandom.uuid }
  let(:sample2_uuid) { SecureRandom.uuid }

  let(:sample1) { create(:v2_sample, name: 'Sample1', uuid: sample1_uuid) }
  let(:sample2) { create(:v2_sample, name: 'Sample2', uuid: sample2_uuid) }

  # requests
  let(:request_type_key) { 'parent_tube_library_request_type' }

  let(:request_type_1) { create :request_type, key: request_type_key }
  let(:request_type_2) { create :request_type, key: request_type_key }

  let(:request_1) { create :library_request, request_type: request_type_1, uuid: 'request-1', submission_id: '1' }
  let(:request_2) { create :library_request, request_type: request_type_2, uuid: 'request-2', submission_id: '1' }

  let(:ancestor_request_1) { create :request, uuid: 'ancestor-request-uuid' }
  let(:ancestor_request_2) { create :request, uuid: 'ancestor-request-uuid' }

  # parent aliquots
  # NB. in scRNA the outer request is an already passed request ie. from the earlier submission
  let(:parent_tube_1_aliquot) { create(:v2_aliquot, sample: sample1, outer_request: ancestor_request_1) }
  let(:parent_tube_2_aliquot) { create(:v2_aliquot, sample: sample2, outer_request: ancestor_request_2) }

  # receptacles
  let(:receptacle_1) { create(:v2_receptacle, qc_results: [], requests_as_source: [request_1]) }
  let(:receptacle_2) { create(:v2_receptacle, qc_results: [], requests_as_source: [request_2]) }

  # parent tube foreign barcodes (need to match values of foreign barcodes in csv file)
  let(:parent_tube_1_foreign_barcode) { 'AB10000001' }
  let(:parent_tube_2_foreign_barcode) { 'AB10000002' }

  # purpose uuids
  let(:parent_tube_1_purpose_uuid) { 'parent-tube-purpose-type-1-uuid' }
  let(:parent_tube_2_purpose_uuid) { 'parent-tube-purpose-type-2-uuid' }

  # purpose names
  let(:parent_tube_1_purpose_name) { 'Parent Tube Purpose Type 1' }
  let(:parent_tube_2_purpose_name) { 'Parent Tube Purpose Type 2' }

  # parent tubes
  let(:parent_tube_1_uuid) { 'tube-1-uuid' }

  let(:parent_tube_1) do
    create(
      :v2_tube,
      uuid: parent_tube_1_uuid,
      purpose_uuid: parent_tube_1_purpose_uuid,
      purpose_name: parent_tube_1_purpose_name,
      aliquots: [parent_tube_1_aliquot],
      receptacle: receptacle_1,
      barcode_number: 1,
      foreign_barcode: parent_tube_1_foreign_barcode
    )
  end

  let(:parent_tube_2_uuid) { 'tube-2-uuid' }
  let(:parent_tube_2) do
    create(
      :v2_tube,
      uuid: parent_tube_2_uuid,
      purpose_uuid: parent_tube_2_purpose_name,
      purpose_name: parent_tube_2_purpose_name,
      aliquots: [parent_tube_2_aliquot],
      receptacle: receptacle_2,
      barcode_number: 2,
      foreign_barcode: parent_tube_2_foreign_barcode
    )
  end

  let(:tube_includes) do
    [:purpose, 'receptacle.aliquots.request.request_type', 'receptacle.requests_as_source.request_type']
  end

  # child aliquots
  let(:child_aliquot1) { create :v2_aliquot }
  let(:child_aliquot2) { create :v2_aliquot }

  # child wells
  let(:child_well1) { create :v2_well, location: 'A1', uuid: '5-well-A1', aliquots: [child_aliquot1] }
  let(:child_well2) { create :v2_well, location: 'B1', uuid: '5-well-B1', aliquots: [child_aliquot2] }

  # child plate
  let(:child_plate_uuid) { 'child-uuid' }
  let(:child_plate_purpose_uuid) { 'child-purpose' }
  let(:child_plate_purpose_name) { 'Child Purpose' }
  let(:child_plate_v2) do
    create :v2_plate,
           uuid: child_plate_uuid,
           purpose_name: child_plate_purpose_name,
           barcode_number: '5',
           size: 96,
           wells: [child_well1, child_well2]
  end

  let(:child_plate_v2) do
    create :v2_plate, uuid: child_plate_uuid, purpose_name: child_plate_purpose_name, barcode_number: '5', size: 96
  end

  let(:user_uuid) { 'user-uuid' }
  let(:user) { json :v1_user, uuid: user_uuid }

  let!(:purpose_config) do
    create :multi_stamp_tubes_using_tube_rack_scan_purpose_config,
           name: child_plate_purpose_name,
           uuid: child_plate_purpose_uuid
  end

  let(:file) do
    fixture_file_upload(
      'spec/fixtures/files/multi_stamp_tubes_using_tube_rack_scan/tube_rack_scan_valid.csv',
      'sequencescape/qc_file'
    )
  end

  let(:file_content) do
    content = file.read
    file.rewind
    content
  end

  let(:stub_upload_file_creation) do
    stub_request(:post, api_url_for(child_plate_uuid, 'qc_files'))
      .with(
        body: file_content,
        headers: {
          'Content-Type' => 'sequencescape/qc_file',
          'Content-Disposition' => 'form-data; filename="tube_rack_scan.csv"'
        }
      )
      .to_return(
        status: 201,
        body: json(:qc_file, filename: 'tube_rack_scan.csv'),
        headers: {
          'content-type' => 'application/json'
        }
      )
  end

  let(:child_plate_v1) do
    # qc_files are created through the API V1. The actions attribute for qcfiles is required by the API V1.
    json :plate, uuid: child_plate_uuid, purpose_uuid: child_plate_purpose_uuid, qc_files_actions: %w[read create]
  end

  before do
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by)
      .with(barcode: 'AB10000001', includes: tube_includes)
      .and_return(parent_tube_1)
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by)
      .with(barcode: 'AB10000002', includes: tube_includes)
      .and_return(parent_tube_2)

    stub_v2_plate(child_plate_v2, stub_search: false, custom_query: [:plate_with_wells, child_plate_v2.uuid])

    stub_api_get(child_plate_uuid, body: child_plate_v1)

    stub_upload_file_creation

    stub_api_get(parent_tube_1_uuid, body: json(:tube))
  end

  context '#new' do
    let(:form_attributes) { { purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid } }

    subject { LabwareCreators::MultiStampTubesUsingTubeRackScan.new(api, form_attributes) }

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::MultiStampTubesUsingTubeRackScan
    end

    it 'renders the "multi_stamp_tubes_using_tube_rack_scan" page' do
      expect(subject.page).to eq('multi_stamp_tubes_using_tube_rack_scan')
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_plate_purpose_uuid)
    end
  end

  context '#save when everything is valid' do
    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

    let!(:ms_plate_creation_request) do
      stub_api_post(
        'pooled_plate_creations',
        payload: {
          pooled_plate_creation: {
            user: user_uuid,
            child_purpose: child_plate_purpose_uuid,
            parents: [parent_tube_1_uuid, parent_tube_2_uuid]
          }
        },
        body: json(:plate_creation, child_plate_uuid: child_plate_uuid)
      )
    end

    let(:transfer_requests) do
      [
        { source_asset: 'tube-1-uuid', target_asset: '5-well-A1', outer_request: 'request-1' },
        { source_asset: 'tube-2-uuid', target_asset: '5-well-B1', outer_request: 'request-2' }
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

    subject { LabwareCreators::MultiStampTubesUsingTubeRackScan.new(api, form_attributes) }

    it 'creates a plate!' do
      # barcode from multi_stamp_tubes_using_tube_rack_scan/tube_rack_scan_valid.csv
      subject.labware.barcode.prefix = 'AB'
      subject.labware.barcode.number = '10000001'

      subject.save
      expect(subject.errors.full_messages).to be_empty

      expect(ms_plate_creation_request).to have_been_made.once
      expect(transfer_creation_request).to have_been_made.once
    end
  end

  context 'when a file is not correctly parsed' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/common_file_handling/tube_rack_with_rack_barcode/' \
          'tube_rack_scan_with_invalid_positions.csv',
        'sequencescape/qc_file'
      )
    end

    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

    subject { LabwareCreators::MultiStampTubesUsingTubeRackScan.new(api, form_attributes) }

    before { subject.validate }

    it 'does not call the validations' do
      expect(subject).not_to be_valid
      expect(subject).not_to receive(:tubes_must_exist_in_lims)
      expect(subject.errors.full_messages).to include(
        'Csv file tube rack scan tube position contains an invalid coordinate, in row 9 [I1]'
      )
    end
  end

  context 'when a tube is not in LIMS' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/multi_stamp_tubes_using_tube_rack_scan/tube_rack_scan_with_unknown_barcode.csv',
        'sequencescape/qc_file'
      )
    end

    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

    subject { LabwareCreators::MultiStampTubesUsingTubeRackScan.new(api, form_attributes) }

    before do
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by)
        .with(barcode: 'AB10000003', includes: tube_includes)
        .and_return(nil)

      subject.validate
    end

    it 'is not valid' do
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to include(
        'Tube barcode AB10000003 not found in the LIMS. ' \
          'Please check the tube barcodes in the scan file are valid tubes.'
      )
    end
  end

  context 'when a tube is not of expected purpose type' do
    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

    let(:parent_tube_2_purpose_uuid) { 'parent-tube-purpose-type-unknown-uuid' }
    let(:parent_tube_2_purpose_name) { 'Parent Tube Purpose Type Unknown' }

    subject { LabwareCreators::MultiStampTubesUsingTubeRackScan.new(api, form_attributes) }

    before { subject.validate }

    it 'is not valid' do
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to include(
        'Tube barcode AB10000002 does not match to one of the expected tube purposes ' \
          '(one of type(s): Parent Tube Purpose Type 1, Parent Tube Purpose Type 2)'
      )
    end
  end

  context 'when a tube does not have an active request of the expected type' do
    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

    let(:request_type_2) { create :request_type, key: 'unrelated_request_type_key' }

    subject { LabwareCreators::MultiStampTubesUsingTubeRackScan.new(api, form_attributes) }

    before { subject.validate }

    it 'is not valid' do
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to include(
        'Tube barcode AB10000002 does not have an expected active request ' \
          '(one of type(s): parent_tube_library_request_type)'
      )
    end

    it 'raises an error if it reaches the code to fetch outer request' do
      expect { subject.send(:source_tube_outer_request_uuid, parent_tube_2) }.to raise_error(
        RuntimeError,
        "No active request of expected type found for tube #{parent_tube_2.human_barcode}"
      )
    end
  end

  context 'when a tube rack does not contain the source tube' do
    # source tube
    let(:source_tube) { subject.labware }
    let(:source_tube_barcode) { "#{source_tube.barcode.prefix}#{source_tube.barcode.number}" }

    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/multi_stamp_tubes_using_tube_rack_scan/tube_rack_scan_valid.csv',
        'sequencescape/qc_file'
      )
    end

    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

    subject { LabwareCreators::MultiStampTubesUsingTubeRackScan.new(api, form_attributes) }

    before { subject.validate }

    it 'is not valid' do
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to include(
        'Uploaded tube rack scan file does not contain the tube scanned ' \
          "on the previous page (#{source_tube_barcode})"
      )
    end
  end
end
