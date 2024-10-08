# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative '../../support/shared_tagging_examples'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::PlateWithTemplate do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  has_a_working_api

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:plate) { json :plate, uuid: parent_uuid, barcode_number: '2', pool_sizes: [8, 8] }
  let(:wells) { json :well_collection, size: 16 }
  let(:wells_in_column_order) { WellHelpers.column_order }
  let(:transfer_template_uuid) { 'custom-transfer-template' } # Defined in spec_helper.rb

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  before do
    create(:templated_transfer_config, name: child_purpose_name, uuid: child_purpose_uuid)
    stub_api_get(parent_uuid, body: plate)
    stub_api_get(parent_uuid, 'wells', body: wells)
  end

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  subject { LabwareCreators::PlateWithTemplate.new(api, form_attributes) }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a LabwareCreators::PlateWithTemplate
    end
  end

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

    let!(:plate_request) { stub_api_get(parent_uuid, body: plate) }

    it 'makes the expected requests' do
      expect_api_v2_posts(
        'Transfer',
        [
          {
            user_uuid: user_uuid,
            source_uuid: parent_uuid,
            destination_uuid: 'child-uuid',
            transfer_template_uuid: transfer_template_uuid
          }
        ]
      )

      expect(subject.save!).to eq true
      expect(plate_creation_request).to have_been_made
    end
  end
end
