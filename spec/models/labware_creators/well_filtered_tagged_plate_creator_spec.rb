# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# In this test, we are testing that the pipeline filters are applied
# and the right requests are associated with the converted tag plate.
RSpec.describe LabwareCreators::WellFilteredTaggedPlateCreator do
  it_behaves_like 'it only allows creation from plates'

  has_a_working_api # Setup API V1 for the test

  let(:user_uuid) { 'user-uuid' }

  # We want to get the first request to get through the filters: filters1_config below
  # Use it on the well because of the new submission
  let(:request_type1) { create(:request_type, key: 'request-type-1') }
  # Use it on the aliquout because of an earlier submission
  let(:request_type2) { create(:request_type, key: 'request-type-2') }
  let(:library_type1) { 'library-type-1' }
  let(:library_type2) { 'library-type-2' }

  let(:requests1) do
    create(:request, request_type: request_type1, library_type: library_type1, state: 'pending')
    create(:request, request_type: request_type1, library_type: library_type1, state: 'pending')
    create(:request, request_type: request_type1, library_type: library_type1, state: 'pending')
  end

  let(:requests2) do
    create(:request, request_type: request_type2, library_type: library_type2, state: 'pending')
    create(:request, request_type: request_type2, library_type: library_type2, state: 'pending')
    create(:request, request_type: request_type2, library_type: library_type2, state: 'pending')
  end

  let(:number_of_wells) { 3 }

  let(:aliquots) do
    [
      create(:v2_aliquot, request: [requests2[0]]),
      create(:v2_aliquot, request: [requests2[1]]),
      create(:v2_aliquot, request: [requests2[2]])
    ]
  end

  let(:wells) do
    [
      create(:v2_well, requests_as_source: [requests1[0]], aliquots: [aliquots[0]]),
      create(:v2_well, requests_as_source: [requests1[1]], aliquots: [aliquots[1]]),
      create(:v2_well, requests_as_source: [requests1[2]], aliquots: [aliquots[2]])
    ]
  end

  let(:parent1_purpose_name) { 'Parent Purpose 1' }
  let(:parent1_purpose_uuid) { 'parent1-purpose-uuid' }
  let(:parent1_uuid) { 'parent1-uuid' }
  let(:parent1) { create(:v2_plate, purpose: parent1_purpose_name, uuid: parent1_uuid, wells: wells) }

  let(:child1_purpose_name) { 'Child Purpose 1' }
  let(:child1_purpose_uuid) { 'child1-purpose-uuid' }

  # same as above; the same relationship is used for the second pipeline
  let(:parent2_purpose_name) { parent1_purpose_name }
  let(:child2_purpose_name) { child1_purpose_name }

  let(:parent3_purpose_name) { 'Parent Purpose 3' }
  let(:child3_purpose_name) { 'Child Purpose 3' }

  let(:filters1_config) { { request_type_key: 'request-type-1', library_type: 'library-type-1' } }
  let(:filters2_config) { { request_type_key: ['request-type-2'], library_type: 'library-type-2' } }
  let(:filters3_config) { { request_type_key: ['request-type-3'] } }

  let(:relationships1_config) { { parent1_purpose_name: child1_purpose_name } }
  let(:relationships2_config) { { parent2_purpose_name: child2_purpose_name } }
  let(:relationships3_config) { { parent3_purpose_name: child3_purpose_name } }

  let(:pipeline1_config) { { filters: filters1_config, relationships: relationships1_config } }
  let(:pipeline2_config) { { filters: filters2_config, relationships: relationships2_config } }
  let(:pipeline3_config) { { filters: filters3_config, relationships: relationships3_config } }

  before do
    create(:purpose_config, name: parent1_purpose_name, uuid: parent1_purpose_uuid)
    create(:purpose_config, name: child1_purpose_name, uuid: child1_purpose_uuid)

    create(:purpose_config, name: parent2_purpose_name)
    create(:purpose_config, name: child2_purpose_name)

    create(:purpose_config, name: parent3_purpose_name)
    create(:purpose_config, name: child3_purpose_name)

    create(:pipeline, **pipeline1_config)
    create(:pipeline, **pipeline2_config)
    create(:pipeline, **pipeline3_config)

    allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(uuid: parent1_uuid).and_return(parent1)
  end

  subject { described_class.new(api, form_attributes) }

  context 'on new' do
    # Test that the labware creator in new action is initialised with the
    # purpose, parent and filters correctly.
    let(:form_attributes) do
      { purpose_uuid: child1_purpose_uuid, parent_uuid: parent1_uuid, filters: filters1_config, user_uuid: user_uuid }
    end

    it 'assigns purpose_uuid' do
      expect(subject.purpose_uuid).to eq(child1_purpose_uuid)
    end

    it 'assigns parent_uuid' do
      expect(subject.parent_uuid).to eq(parent1_uuid)
    end

    it 'assigns filters' do
      expect(subject.filters).to eq(filters1_config)
    end

    it 'assigns user uuid' do
      expect(subject.user_uuid).to eq(user_uuid)
    end
  end

  context 'on create' do
    # Test that the labware creator in create action after form submit uses the
    # right request type and library type in setting up the transfer requests.
    let(:child1_uuid) { 'child1-uuid' }
    # Use the following as the converted tag plate
    let(:child1) { create(:v2_plate, purpose: child1_purpose_name, uuid: child1_uuid) }

    before { allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(uuid: child1_uuid).and_return(child1) }

    let(:tag_plate_barcode) { child1.barcode.human }
    let(:tag_plate_uuid) { child1_uuid }
    let(:tag_template_uuid) { 'tag-template-uuid' }
    let(:form_attributes) do
      {
        purpose_uuid: child1_purpose_uuid,
        parent_uuid: parent1_uuid,
        filters: filters1_config,
        tag_plate_barcode: tag_plate_barcode,
        user_uuid: user_uuid,
        tag_plate: {
          asset_uuid: tag_plate_uuid,
          template_uuid: tag_template_uuid
        }
      }
    end

    let(:transfer_requests) do
      [
        { source_asset: wells[0].uuid, destination_asset: child1.wells[0].uuid, outer_request: requests1[0].uuid },
        { source_asset: wells[1].uuid, destination_asset: child1.wells[1].uuid, outer_request: requests1[1].uuid },
        { source_asset: wells[2].uuid, destination_asset: child1.wells[2].uuid, outer_request: requests1[2].uuid }
      ]
    end

    it 'filters the right requests' do
      expect(subject).to receive_message_chain(:api, :transfer_request_collection, :create!).with(
        user: user_uuid,
        transfer_requests: transfer_requests
      )
      expect(subject.save).to be_truthy
    end
  end
end
