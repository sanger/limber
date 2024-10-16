# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

# Parent in a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
RSpec.describe LabwareCreators::CustomPooledTubes, with: :uploader do
  has_a_working_api

  it_behaves_like 'it only allows creation from charged and passed plates'

  subject { described_class.new(api, form_attributes) }

  it 'should have page' do
    expect(described_class.page).to eq 'custom_pooled_tubes'
  end

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose) { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid) { SecureRandom.uuid }
  let(:parent) { json :plate, uuid: parent_uuid, stock_plate_barcode: 5, qc_files_actions: %w[read create] }
  let(:v2_plate) { create(:v2_plate, uuid: parent_uuid) }
  let(:form_attributes) { { purpose_uuid:, parent_uuid: } }

  let(:wells_json) { json :well_collection, size: 16, default_state: 'passed' }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a LabwareCreators::CustomPooledTubes
    end
  end

  context '#source_plate' do
    before do
      stub_api_get(parent_uuid, body: parent)
      stub_v2_plate(v2_plate, stub_search: false)
    end

    it 'returns V2 plate' do
      expect(subject.source_plate).to eq(v2_plate)
    end
  end

  context '#save' do
    let(:file_content) do
      content = file.read
      file.rewind
      content
    end

    let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid:, file: } }

    let(:stub_qc_file_creation) do
      stub_request(:post, api_url_for(parent_uuid, 'qc_files')).with(
        body: file_content,
        headers: {
          'Content-Type' => 'sequencescape/qc_file',
          'Content-Disposition' => 'form-data; filename="robot_pooling_file.csv"'
        }
      ).to_return(
        status: 201,
        body: json(:qc_file, filename: 'pooling_file.csv'),
        headers: {
          'content-type' => 'application/json'
        }
      )
    end

    def expect_specific_tube_creation
      child_tubes = [
        create(:v2_tube, name: 'DN5 A1:B2', uuid: 'tube-0'),
        create(:v2_tube, name: 'DN5 C1:G2', uuid: 'tube-1')
      ]

      # Create a mock for the specific tube creation.
      specific_tube_creation = double
      allow(specific_tube_creation).to receive(:children).and_return(child_tubes)

      # Expect the post request and return the mock.
      expect_api_v2_posts(
        'SpecificTubeCreation',
        [
          {
            child_purpose_uuids: [purpose_uuid, purpose_uuid],
            parent_uuids: [parent_uuid],
            tube_attributes: child_tubes.map { |tube| { name: tube.name } },
            user_uuid: user_uuid
          }
        ],
        [specific_tube_creation]
      )
    end

    # Used to fetch the pools. This is the kind of thing we could pass through from a custom form
    let(:stub_parent_request) do
      stub_v2_plate(v2_plate, stub_search: false)
      stub_api_get(parent_uuid, body: parent)
      stub_api_get(parent_uuid, 'wells', body: wells_json)
    end

    let(:transfer_creation_request) do
      stub_api_post(
        'transfer_request_collections',
        payload: {
          transfer_request_collection: {
            user: user_uuid,
            transfer_requests: [
              { 'source_asset' => 'example-well-uuid-0', 'target_asset' => 'tube-0' },
              { 'source_asset' => 'example-well-uuid-1', 'target_asset' => 'tube-0' },
              { 'source_asset' => 'example-well-uuid-3', 'target_asset' => 'tube-0' },
              { 'source_asset' => 'example-well-uuid-4', 'target_asset' => 'tube-0' },
              { 'source_asset' => 'example-well-uuid-5', 'target_asset' => 'tube-0' },
              { 'source_asset' => 'example-well-uuid-6', 'target_asset' => 'tube-0' },
              { 'source_asset' => 'example-well-uuid-7', 'target_asset' => 'tube-0' },
              { 'source_asset' => 'example-well-uuid-8', 'target_asset' => 'tube-0' },
              { 'source_asset' => 'example-well-uuid-9', 'target_asset' => 'tube-0' },
              { 'source_asset' => 'example-well-uuid-2', 'target_asset' => 'tube-1' },
              { 'source_asset' => 'example-well-uuid-10', 'target_asset' => 'tube-1' },
              { 'source_asset' => 'example-well-uuid-11', 'target_asset' => 'tube-1' },
              { 'source_asset' => 'example-well-uuid-12', 'target_asset' => 'tube-1' },
              { 'source_asset' => 'example-well-uuid-13', 'target_asset' => 'tube-1' },
              { 'source_asset' => 'example-well-uuid-14', 'target_asset' => 'tube-1' }
            ]
          }
        },
        body: '{}'
      )
    end

    before do
      stub_parent_request
      stub_qc_file_creation
      transfer_creation_request
    end

    context 'with a valid file' do
      let(:file) do
        fixture_file_upload('spec/fixtures/files/custom_pooled_tubes/pooling_file.csv', 'sequencescape/qc_file')
      end

      it 'pools according to the file' do
        expect_specific_tube_creation

        expect(subject.save).to be_truthy
        expect(stub_qc_file_creation).to have_been_made.once
        expect(transfer_creation_request).to have_been_made.once
      end
    end

    context 'with an invalid file' do
      let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

      it 'is false' do
        expect(subject.save).to be false
      end
    end

    context 'with empty wells includes' do
      let(:file) do
        fixture_file_upload('spec/fixtures/files/custom_pooled_tubes/pooling_file.csv', 'sequencescape/qc_file')
      end
      let(:wells_json) { json :well_collection, size: 8 }

      it 'is false' do
        expect(subject.save).to be false
      end
    end
  end
end
