# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

# Parent in a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
RSpec.describe LabwareCreators::PooledTubesFromWholeTubes do
  include FeatureHelpers
  it_behaves_like 'it only allows creation from tubes'

  subject { described_class.new(api, form_attributes) }

  let(:user_uuid)     { SecureRandom.uuid }
  let(:purpose_uuid)  { SecureRandom.uuid }
  let(:purpose)       { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid)   { SecureRandom.uuid }
  let(:parent2_uuid)  { SecureRandom.uuid }
  let(:parent)        { create :v2_tube, uuid: parent_uuid, barcode_number: 1 }
  let(:parent2)       { create :v2_tube, uuid: parent2_uuid, barcode_number: 2 }
  let(:child_uuid)    { SecureRandom.uuid }
  let(:template_uuid) { SecureRandom.uuid }

  let(:barcodes) do
    [
      SBCF::SangerBarcode.new(prefix: 'NT', number: 1).machine_barcode.to_s,
      SBCF::SangerBarcode.new(prefix: 'NT', number: 2).machine_barcode.to_s
    ]
  end

  before do
    create :purpose_config,
           submission: {
             template_uuid: template_uuid,
             request_options: { read_length: 150 }
           },
           uuid: purpose_uuid
  end

  describe '#new' do
    it_behaves_like 'it has a custom page', 'pooled_tubes_from_whole_tubes'
    has_a_working_api

    let(:form_attributes) { { purpose_uuid: purpose_uuid, parent_uuid: parent_uuid } }
  end

  describe '#save!' do
    has_a_working_api

    let(:form_attributes) do
      {
        user_uuid: user_uuid,
        purpose_uuid: purpose_uuid,
        parent_uuid: parent_uuid,
        barcodes: barcodes
      }
    end

    let(:tube_creation_request_uuid) { SecureRandom.uuid }

    let!(:tube_creation_request) do
      # TODO: In reality we want to link in all four parents.
      stub_api_post(
        'tube_from_tube_creations',
        payload: {
          tube_from_tube_creation: {
            user: user_uuid,
            parent: parent_uuid,
            child_purpose: purpose_uuid
          }
        },
        body: json(:tube_creation, child_uuid: child_uuid)
      )
    end
    # Find out what tubes we've just made!
    let(:tube_creation_children_request) do
      stub_api_get(tube_creation_request_uuid, 'children',
                   body: json(:single_study_multiplexed_library_tube_collection, names: ['DN2+']))
    end

    let(:transfer_creation_request) do
      stub_api_post('transfer_request_collections',
                    payload: { transfer_request_collection: {
                      user: user_uuid,
                      transfer_requests: [
                        { 'source_asset' => parent_uuid, 'target_asset' => child_uuid },
                        { 'source_asset' => parent2_uuid, 'target_asset' => child_uuid }
                      ]
                    } },
                    body: '{}')
    end

    before do
      allow(Sequencescape::Api::V2::Tube).to receive(:find_all).with(
        { barcode: barcodes },
        includes: []
      ).and_return([parent, parent2])

      tube_creation_request
      tube_creation_children_request
      transfer_creation_request
    end

    context 'with compatible tubes' do
      it 'pools from all the tubes' do
        expect(subject.save!).to be_truthy
        expect(tube_creation_request).to have_been_made.once
        expect(transfer_creation_request).to have_been_made.once
      end
    end
  end
end
