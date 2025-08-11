# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# # Up to 96 tubes are transferred onto a single 96-well plate.
RSpec.describe LabwareCreators::MultiStampTubesUsingTubeRackScan, with: :uploader do
  it_behaves_like 'it only allows creation from tubes'

  # samples
  let(:sample1_uuid) { SecureRandom.uuid }
  let(:sample2_uuid) { SecureRandom.uuid }

  let(:sample1) { create(:sample, name: 'Sample1', uuid: sample1_uuid) }
  let(:sample2) { create(:sample, name: 'Sample2', uuid: sample2_uuid) }

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
  let(:parent_tube_1_aliquot) { create(:aliquot, sample: sample1, outer_request: ancestor_request_1) }
  let(:parent_tube_2_aliquot) { create(:aliquot, sample: sample2, outer_request: ancestor_request_2) }

  # receptacles
  let(:receptacle_1) { create(:receptacle, qc_results: [], requests_as_source: [request_1]) }
  let(:receptacle_2) { create(:receptacle, qc_results: [], requests_as_source: [request_2]) }

  # parent tube foreign barcodes (need to match values of foreign barcodes in csv file)
  let(:parent_tube_1_foreign_barcode) { 'AB10000001' }
  let(:parent_tube_2_foreign_barcode) { 'AB10000002' }

  # purpose uuids
  let(:parent_tube_1_purpose_uuid) { 'parent-tube-purpose-type-1-uuid' }

  # purpose names
  let(:parent_tube_1_purpose_name) { 'Parent Tube Purpose Type 1' }
  let(:parent_tube_2_purpose_name) { 'Parent Tube Purpose Type 2' }

  # parent tubes
  let(:parent_tube_1_uuid) { 'tube-1-uuid' }

  let(:parent_tube_1) do
    create(
      :tube,
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
      :tube,
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

  # child plate
  let(:child_plate_purpose_uuid) { 'child-purpose' }
  let(:child_plate_purpose_name) { 'Child Purpose' }
  let(:child_plate) { create :plate, purpose_name: child_plate_purpose_name, barcode_number: '5', size: 96 }

  let(:user_uuid) { 'user-uuid' }

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

  before do
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(
      barcode: 'AB10000001',
      includes: tube_includes
    ).and_return(parent_tube_1)
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(
      barcode: 'AB10000002',
      includes: tube_includes
    ).and_return(parent_tube_2)

    stub_tube(parent_tube_1)
  end

  describe '#new' do
    subject { described_class.new(form_attributes) }

    let(:form_attributes) { { purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid } }

    it 'can be created' do
      expect(subject).to be_a described_class
    end

    it 'renders the "multi_stamp_tubes_using_tube_rack_scan" page' do
      expect(subject.page).to eq('multi_stamp_tubes_using_tube_rack_scan')
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_plate_purpose_uuid)
    end
  end

  describe '#save when everything is valid' do
    subject { described_class.new(form_attributes) }

    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
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
          filename: 'tube_rack_scan.csv',
          relationships: {
            labware: {
              data: {
                id: child_plate.id,
                type: 'labware'
              }
            }
          }
        }
      ]
    end

    let(:pooled_plates_attributes) do
      [
        {
          child_purpose_uuid: child_plate_purpose_uuid,
          parent_uuids: [parent_tube_1_uuid, parent_tube_2_uuid],
          user_uuid: user_uuid
        }
      ]
    end

    let(:transfer_requests_attributes) do
      [
        { source_asset: 'tube-1-uuid', target_asset: '5-well-A1', outer_request: 'request-1' },
        { source_asset: 'tube-2-uuid', target_asset: '5-well-B1', outer_request: 'request-2' }
      ]
    end

    it 'creates a plate!' do
      # barcode from multi_stamp_tubes_using_tube_rack_scan/tube_rack_scan_valid.csv
      subject.labware.labware_barcode = { 'human_barcode' => 'AB10000001', 'machine_barcode' => 'AB10000001' }

      expect_pooled_plate_creation
      expect_qc_file_creation
      expect_transfer_request_collection_creation

      subject.save

      expect(subject.errors.full_messages).to be_empty
    end
  end

  context 'when a file is not correctly parsed' do
    subject { described_class.new(form_attributes) }

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
    subject { described_class.new(form_attributes) }

    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/multi_stamp_tubes_using_tube_rack_scan/tube_rack_scan_with_unknown_barcode.csv',
        'sequencescape/qc_file'
      )
    end

    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

    before do
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(
        barcode: 'AB10000003',
        includes: tube_includes
      ).and_return(nil)

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
    subject { described_class.new(form_attributes) }

    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

    let(:parent_tube_2_purpose_name) { 'Parent Tube Purpose Type Unknown' }

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
    subject { described_class.new(form_attributes) }

    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

    let(:request_type_2) { create :request_type, key: 'unrelated_request_type_key' }

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

  context 'when a tube rack has a source tube with a ean13 barcode' do
    # source tube
    subject { described_class.new(form_attributes) }

    let(:source_tube) { subject.labware }
    let(:source_tube_barcode) { source_tube.barcode.machine }

    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/multi_stamp_tubes_using_tube_rack_scan/tube_rack_scan_valid.csv',
        'sequencescape/qc_file'
      )
    end

    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

    before { subject.validate }

    it 'is not valid' do
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to include(
        'Uploaded tube rack scan file does not work with ean13-barcoded tube ' \
        "scanned on the previous page (#{source_tube_barcode})"
      )
    end
  end

  context 'when a tube rack does not contain the source tube' do
    # source tube
    subject { described_class.new(form_attributes) }

    let(:source_tube) { subject.labware }
    let(:source_tube_barcode) { source_tube.barcode.machine }

    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/multi_stamp_tubes_using_tube_rack_scan/tube_rack_scan_valid.csv',
        'sequencescape/qc_file'
      )
    end

    let(:form_attributes) do
      { user_uuid: user_uuid, purpose_uuid: child_plate_purpose_uuid, parent_uuid: parent_tube_1_uuid, file: file }
    end

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
