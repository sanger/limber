# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

# Parent in a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
RSpec.describe LabwareCreators::PooledTubesFromWholePlates, with: :uploader do
  include FeatureHelpers
  it_behaves_like 'it only allows creation from tagged plates'

  subject { described_class.new(api, form_attributes) }

  it 'should have page' do
    expect(described_class.page).to eq 'pooled_tubes_from_whole_plates'
  end

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose) { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid) { SecureRandom.uuid }
  let(:parent2_uuid) { SecureRandom.uuid }
  let(:parent3_uuid) { SecureRandom.uuid }
  let(:parent4_uuid) { SecureRandom.uuid }
  let(:parent) { associated :plate, uuid: parent_uuid, barcode_number: 1 }
  let(:parent2) { associated :plate, uuid: parent2_uuid, barcode_number: 2 }
  let(:parent3) { associated :plate, uuid: parent3_uuid, barcode_number: 3 }
  let(:parent4) { associated :plate, uuid: parent4_uuid, barcode_number: 4 }

  let(:barcodes) do
    [
      SBCF::SangerBarcode.new(prefix: 'DN', number: 1).human_barcode,
      SBCF::SangerBarcode.new(prefix: 'DN', number: 2).human_barcode,
      SBCF::SangerBarcode.new(prefix: 'DN', number: 3).human_barcode,
      SBCF::SangerBarcode.new(prefix: 'DN', number: 4).human_barcode
    ]
  end

  describe '#new' do
    it_behaves_like 'it has a custom page', 'pooled_tubes_from_whole_plates'
    has_a_working_api

    let(:form_attributes) { { purpose_uuid:, parent_uuid: } }
  end

  describe '#save!' do
    has_a_working_api

    let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid:, barcodes: } }

    let(:tube_creation_request_uuid) { SecureRandom.uuid }

    let(:tube_creation_request) do
      # TODO: In reality we want to link in all four parents.
      stub_api_post(
        'specific_tube_creations',
        payload: {
          specific_tube_creation: {
            user: user_uuid,
            parent: parent_uuid,
            child_purposes: [purpose_uuid],
            tube_attributes: [{ name: 'DN2+' }]
          }
        },
        body: json(:specific_tube_creation, uuid: tube_creation_request_uuid, children_count: 1)
      )
    end

    # Find out what tubes we've just made!
    let(:tube_creation_children_request) do
      stub_api_get(tube_creation_request_uuid, 'children', body: json(:tube_collection, names: ['DN2+']))
    end

    # Used to fetch the pools. This is the kind of thing we could pass through from a custom form
    let(:stub_barcode_searches) { stub_asset_search(barcodes, [parent, parent2, parent3, parent4]) }

    before do
      stub_barcode_searches
      tube_creation_children_request
      tube_creation_request
    end

    context 'with compatible plates' do
      it 'pools from all the plates' do
        expect_api_v2_posts(
          'Transfer',
          [parent_uuid, parent2_uuid, parent3_uuid, parent4_uuid].map do |source_uuid|
            { user_uuid:, source_uuid:, destination_uuid: 'tube-0', transfer_template_uuid: 'whole-plate-to-tube' }
          end
        )

        expect(subject.save!).to be_truthy
        expect(tube_creation_request).to have_been_made.once
      end
    end
  end
end
