# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative '../../support/shared_tagging_examples'
require_relative 'shared_examples'

# Presents the user with a form allowing them to scan in up to four plates
# which will then be pooled together according to pre-capture pools
RSpec.describe LabwareCreators::MultiPlatePool do
  it_behaves_like 'it only allows creation from tagged plates'

  has_a_working_api

  let(:plate_uuid) { 'example-plate-uuid' }
  let(:plate_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:plate) { json :plate, uuid: plate_uuid, barcode_number: '2', pool_sizes: [8, 8] }
  let(:wells) { json :well_collection, size: 16 }
  let(:wells_in_column_order) { WellHelpers.column_order }
  let(:transfer_template_uuid) { 'transfer-template-uuid' }
  let(:transfer_template) { json :transfer_template, uuid: transfer_template_uuid }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let(:plate_request) { stub_api_get(plate_uuid, body: plate) }
  let(:wells_request) { stub_api_get(plate_uuid, 'wells', body: wells) }

  before do
    create :purpose_config, name: child_purpose_name, uuid: child_purpose_uuid
    plate_request
    wells_request
  end

  context 'on new' do
    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: plate_uuid } }

    subject { LabwareCreators::MultiPlatePool.new(api, form_attributes) }

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::MultiPlatePool
    end

    it 'renders the "multi_plate_pool" page' do
      expect(subject.page).to eq('multi_plate_pool')
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_purpose_uuid)
    end
  end

  context 'on create' do
    subject { LabwareCreators::MultiPlatePool.new(api, form_attributes.merge(user_uuid: user_uuid)) }

    let(:plate_b_uuid) { 'example-plate-b-uuid' }
    let(:plate_b_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }

    let(:child_plate_uuid) { 'child-plate-uuid' }

    let(:form_attributes) do
      {
        parent_uuid: plate_uuid,
        purpose_uuid: child_purpose_uuid,
        transfers: {
          plate_uuid => {
            'A1' => 'A1',
            'B1' => 'A1'
          },
          plate_b_uuid => {
            'A1' => 'B1',
            'B1' => 'B1'
          }
        }
      }
    end

    let(:child_plate) { create :v2_plate }

    let(:pooled_plate_creation) do
      response = double
      allow(response).to receive(:child).and_return(child_plate)

      response
    end

    let!(:bulk_transfer_request) do
      stub_api_post(
        'bulk_transfers',
        payload: {
          bulk_transfer: {
            user: user_uuid,
            well_transfers: [
              {
                'source_uuid' => plate_uuid,
                'source_location' => 'A1',
                'destination_uuid' => child_plate.uuid,
                'destination_location' => 'A1'
              },
              {
                'source_uuid' => plate_uuid,
                'source_location' => 'B1',
                'destination_uuid' => child_plate.uuid,
                'destination_location' => 'A1'
              },
              {
                'source_uuid' => plate_b_uuid,
                'source_location' => 'A1',
                'destination_uuid' => child_plate.uuid,
                'destination_location' => 'B1'
              },
              {
                'source_uuid' => plate_b_uuid,
                'source_location' => 'B1',
                'destination_uuid' => child_plate.uuid,
                'destination_location' => 'B1'
              }
            ]
          }
        },
        body: json(:plate_creation, child_uuid: child_plate.uuid)
      )
    end

    def expect_pooled_plate_creation
      expect_api_v2_posts(
        'PooledPlateCreation',
        [{ child_purpose_uuid: child_purpose_uuid, parent_uuids: [plate_uuid, plate_b_uuid], user_uuid: user_uuid }],
        [pooled_plate_creation]
      )
    end

    context '#save!' do
      it 'creates a plate!' do
        expect_pooled_plate_creation

        subject.save!

        expect(bulk_transfer_request).to have_been_made.once
      end
    end
  end
end
