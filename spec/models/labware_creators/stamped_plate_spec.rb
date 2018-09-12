# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative '../../support/shared_tagging_examples'
require_relative 'shared_examples'

# Uses a custom transfer template to transfer material into the new plate
RSpec.describe LabwareCreators::StampedPlate do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  has_a_working_api

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:plate_size) { 96 }
  let(:plate) { create :v2_plate, uuid: parent_uuid, barcode_number: '2', size: plate_size }
  let(:wells) { json :well_collection, size: 16 }
  let(:wells_in_column_order) { WellHelpers.column_order }
  let(:transfer_template_uuid) { 'custom-pooling' }
  let(:transfer_template) { json :transfer_template, uuid: transfer_template_uuid }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let(:wells_request) { stub_api_get(parent_uuid, 'wells', body: wells) }

  before do
    Settings.purposes = {
      child_purpose_uuid => build(:purpose_config, name: child_purpose_name)
    }
    stub_v2_plate(plate, stub_search: false)
    wells_request
  end

  let(:form_attributes) do
    {
      purpose_uuid: child_purpose_uuid,
      parent_uuid:  parent_uuid,
      user_uuid: user_uuid
    }
  end

  subject do
    LabwareCreators::StampedPlate.new(api, form_attributes)
  end

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a LabwareCreators::StampedPlate
    end
  end

  shared_examples 'a stamped plate creator' do
    describe '#save!' do
      let!(:plate_creation_request) do
        stub_api_post('plate_creations',
                      payload: { plate_creation: {
                        parent: parent_uuid,
                        child_purpose: child_purpose_uuid,
                        user: user_uuid
                      } },
                      body: json(:plate_creation))
      end

      let!(:plate_request) do
        stub_v2_plate(plate, stub_search: false)
      end

      let!(:transfer_template_request) do
        stub_api_get(transfer_template_uuid, body: transfer_template)
      end

      let(:expected_transfers) { WellHelpers.stamp_hash(plate_size) }

      let!(:transfer_creation_request) do
        stub_api_post(transfer_template_uuid,
                      payload: { transfer: {
                        destination: 'child-uuid',
                        source: parent_uuid,
                        user: user_uuid,
                        transfers: expected_transfers
                      } },
                      body: '{}')
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
    it_behaves_like 'a stamped plate creator'
  end

  context '384 well plate' do
    let(:plate_size) { 384 }
    it_behaves_like 'a stamped plate creator'
  end
end
