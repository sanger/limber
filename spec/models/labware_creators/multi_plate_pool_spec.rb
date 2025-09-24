# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Presents the user with a form allowing them to scan in up to four plates
# which will then be pooled together according to pre-capture pools
RSpec.describe LabwareCreators::MultiPlatePool do
  it_behaves_like 'it only allows creation from tagged plates'

  let(:plate_uuid) { 'example-plate-uuid' }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  before { create :purpose_config, name: child_purpose_name, uuid: child_purpose_uuid }

  context 'on new' do
    subject { described_class.new(form_attributes) }

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: plate_uuid } }

    it 'can be created' do
      expect(subject).to be_a described_class
    end

    it 'renders the "multi_plate_pool" page' do
      expect(subject.page).to eq('multi_plate_pool')
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_purpose_uuid)
    end
  end

  context 'on create' do
    subject { described_class.new(form_attributes.merge(user_uuid:)) }

    let(:plate_b_uuid) { 'example-plate-b-uuid' }

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

    let(:bulk_transfer_attributes) do
      [
        {
          user_uuid: user_uuid,
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
      ]
    end

    let(:pooled_plates_attributes) do
      [{ child_purpose_uuid: child_purpose_uuid, parent_uuids: [plate_uuid, plate_b_uuid], user_uuid: user_uuid }]
    end

    describe '#save!' do
      it 'creates a plate!' do
        expect_bulk_transfer_creation
        expect_pooled_plate_creation

        subject.save!
      end
    end
  end
end
