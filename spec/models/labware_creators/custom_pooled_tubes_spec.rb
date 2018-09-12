# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

# Parent in a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
RSpec.describe LabwareCreators::CustomPooledTubes, with: :uploader do
  it_behaves_like 'it only allows creation from charged and passed plates'

  subject do
    described_class.new(api, form_attributes)
  end

  it 'should have page' do
    expect(described_class.page).to eq 'custom_pooled_tubes'
  end

  let(:user_uuid)    { SecureRandom.uuid }
  let(:user)         { json :user, uuid: user_uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose)      { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid)  { SecureRandom.uuid }
  let(:parent)       { json :plate, uuid: parent_uuid, stock_plate_barcode: 5, qc_files_actions: %w[read create] }

  let(:wells_json) { json :well_collection, size: 16, default_state: 'passed' }

  context 'on new' do
    has_a_working_api

    let(:form_attributes) do
      {
        purpose_uuid: purpose_uuid,
        parent_uuid:  parent_uuid
      }
    end

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::CustomPooledTubes
    end
  end

  context '#save!' do
    has_a_working_api

    let(:file_content) do
      content = file.read
      file.rewind
      content
    end

    let(:form_attributes) do
      {
        user_uuid: user_uuid,
        purpose_uuid: purpose_uuid,
        parent_uuid: parent_uuid,
        file: file
      }
    end

    let(:stub_qc_file_creation) do
      stub_request(:post, api_url_for(parent_uuid, 'qc_files'))
        .with(
          body: file_content,
          headers: {
            'Content-Type' => 'sequencescape/qc_file',
            'Content-Disposition' => 'form-data; filename="robot_pooling_file.csv"'
          }
        ).to_return(
          status: 201,
          body: json(:qc_file, filename: 'pooling_file.csv'),
          headers: { 'content-type' => 'application/json' }
        )
    end

    let(:tube_creation_request_uuid) { SecureRandom.uuid }

    let(:tube_creation_request) do
      stub_api_post(
        'specific_tube_creations',
        payload: {
          specific_tube_creation: {
            user: user_uuid,
            parent: parent_uuid,
            child_purposes: [purpose_uuid, purpose_uuid],
            tube_attributes: [{ name: 'DN5 A1:B2' }, { name: 'DN5 C1:G2' }]
          }
        },
        body: json(:specific_tube_creation, uuid: tube_creation_request_uuid, children_count: 2)
      )
    end

    # Find out what tubes we've just made!
    let(:tube_creation_children_request) do
      stub_api_get(tube_creation_request_uuid, 'children', body: json(:tube_collection, names: ['DN5 A1:B2', 'DN5 C1:G2']))
    end

    # Used to fetch the pools. This is the kind of thing we could pass through from a custom form
    let(:stub_parent_request) do
      stub_api_get(parent_uuid, body: parent)
      stub_api_get(parent_uuid, 'wells', body: wells_json)
    end

    let(:transfer_creation_request) do
      stub_api_post('transfer_request_collections',
                    payload: { transfer_request_collection: {
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
                    } },
                    body: '{}')
    end

    before do
      stub_parent_request
      stub_qc_file_creation
      tube_creation_children_request
      tube_creation_request
      transfer_creation_request
    end

    context 'with a valid file' do
      let(:file) { fixture_file_upload('spec/fixtures/files/pooling_file.csv', 'sequencescape/qc_file') }

      it 'pools according to the file' do
        expect(subject.save!).to be_truthy
        expect(stub_qc_file_creation).to have_been_made.once
        expect(tube_creation_request).to have_been_made.once
        expect(transfer_creation_request).to have_been_made.once
      end
    end

    context 'with an invalid file' do
      let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

      it 'raises an exception' do
        # Note: This really shouldn't be an exception, but need to make some other adjustments first.
        expect { subject.save! }.to raise_error(LabwareCreators::ResourceInvalid)
      end
    end

    context 'with empty wells includes' do
      let(:file) { fixture_file_upload('spec/fixtures/files/pooling_file.csv', 'sequencescape/qc_file') }
      let(:wells_json) { json :well_collection, size: 8 }

      it 'raises an exception' do
        # Note: This really shouldn't be an exception, but need to make some other adjustments first.
        expect { subject.save! }.to raise_error(LabwareCreators::ResourceInvalid)
      end
    end
  end
end
