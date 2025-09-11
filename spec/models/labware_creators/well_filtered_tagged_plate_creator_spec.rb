# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# In this test, we are testing that the pipeline filters are applied
# and the right requests are associated with the converted tag plate.
RSpec.describe LabwareCreators::WellFilteredTaggedPlateCreator do
  subject { described_class.new(api, form_attributes) }

  it_behaves_like 'it only allows creation from plates'

  has_a_working_api # Setup API V1 for the test

  let(:user_uuid) { 'user-uuid' }

  # We want the first request type to get through the filters.

  # Use it on the well because of the new submission.
  let(:request_type1) { create(:request_type, key: 'request-type-1') }
  let(:library_type1) { 'library-type-1' }

  # Use it on the aliquout because of an earlier submission.
  let(:request_type2) { create(:request_type, key: 'request-type-2') }
  let(:library_type2) { 'library-type-2' }

  let(:new_submission) { create(:v2_submission) }

  # Requests on the wells because of the new submission.
  let(:new_requests) do
    [
      create(
        :request,
        :uuid,
        request_type: request_type1,
        library_type: library_type1,
        state: 'pending',
        submission: new_submission
      ),
      create(
        :request,
        :uuid,
        request_type: request_type1,
        library_type: library_type1,
        state: 'pending',
        submission: new_submission
      ),
      create(
        :request,
        :uuid,
        request_type: request_type1,
        library_type: library_type1,
        state: 'pending',
        submission: new_submission
      )
    ]
  end

  # Requests on aliquots because of an earlier submission.
  let(:old_requests) do
    [
      create(:request, :uuid, request_type: request_type2, library_type: library_type2, state: 'pending'),
      create(:request, :uuid, request_type: request_type2, library_type: library_type2, state: 'pending'),
      create(:request, :uuid, request_type: request_type2, library_type: library_type2, state: 'pending')
    ]
  end

  let(:aliquots) do
    [
      create(:v2_aliquot, request: [old_requests[0]]),
      create(:v2_aliquot, request: [old_requests[1]]),
      create(:v2_aliquot, request: [old_requests[2]])
    ]
  end

  let(:wells) do
    [
      create(:v2_well, requests_as_source: [new_requests[0]], aliquots: [aliquots[0]], location: 'A1'),
      create(:v2_well, requests_as_source: [new_requests[1]], aliquots: [aliquots[1]], location: 'B1'),
      create(:v2_well, requests_as_source: [new_requests[2]], aliquots: [aliquots[2]], location: 'C1')
    ]
  end

  let(:parent_purpose_name) { 'Parent Purpose 1' }
  let(:parent_purpose_uuid) { 'parent-purpose-uuid' }
  let(:parent_uuid) { 'parent-uuid' }
  let(:parent) do
    create(
      :v2_plate,
      :has_pooling_metadata,
      purpose: parent_purpose_name,
      uuid: parent_uuid,
      wells: wells,
      submission_pools: create_list(:v2_submission_pool, 1)
    )
  end

  let(:child_purpose_name) { 'Child Purpose 1' }
  let(:child_purpose_uuid) { 'child-purpose-uuid' }

  let(:filters1_config) { { request_type_key: 'request-type-1', library_type: 'library-type-1' } }
  let(:filters2_config) { { request_type_key: ['request-type-2'], library_type: 'library-type-2' } }

  let(:relationships_config) { { parent_purpose_name: child_purpose_name } }

  let(:pipeline1_config) { { filters: filters1_config, relationships: relationships_config } }
  let(:pipeline2_config) { { filters: filters2_config, relationships: relationships_config } }

  before do
    create(:purpose_config, name: parent_purpose_name, uuid: parent_purpose_uuid)
    create(:purpose_config, name: child_purpose_name, uuid: child_purpose_uuid)

    create(:pipeline, **pipeline1_config)
    create(:pipeline, **pipeline2_config)

    # It will receive the parent plate.
    allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(uuid: parent_uuid).and_return(parent)
  end

  context 'on new' do
    # Test that the labware creator in new action is initialised with the
    # purpose, parent and filters correctly.
    let(:form_attributes) do
      { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, filters: filters1_config, user_uuid: user_uuid }
    end

    it 'assigns purpose_uuid' do
      expect(subject.purpose_uuid).to eq(child_purpose_uuid)
    end

    it 'assigns parent_uuid' do
      expect(subject.parent_uuid).to eq(parent_uuid)
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

    # Use the following as the tag plate.
    let(:child_uuid) { 'child-uuid' }
    let(:child) { create(:v2_plate, purpose: child_purpose_name, uuid: child_uuid) }

    let(:tag_plate_barcode) { child.barcode.human }
    let(:tag_plate_uuid) { child_uuid }
    let(:tag_template_uuid) { 'tag-template-uuid' }
    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent_uuid,
        filters: filters1_config,
        tag_plate_barcode: tag_plate_barcode,
        user_uuid: user_uuid,
        tag_plate: {
          asset_uuid: tag_plate_uuid,
          template_uuid: tag_template_uuid
        }
      }
    end

    before do
      # It will receive the child plate, which is an existing tag plate.
      allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(uuid: child_uuid).and_return(child)
    end

    let(:plate_conversions_attributes) do
      [{ parent_uuid: parent_uuid, purpose_uuid: child_purpose_uuid, target_uuid: child_uuid, user_uuid: user_uuid }]
    end

    let(:state_changes_attributes) do
      [{ reason: 'Used in Library creation', target_state: 'exhausted', target_uuid: child_uuid, user_uuid: user_uuid }]
    end

    let(:tag_layouts_attributes) do
      [
        {
          enforce_uniqueness: false,
          plate_uuid: child_uuid,
          tag_layout_template_uuid: tag_template_uuid,
          user_uuid: user_uuid
        }
      ]
    end

    let(:transfer_requests_attributes) do
      [
        { source_asset: wells[0].uuid, target_asset: child.wells[0].uuid, outer_request: new_requests[0].uuid },
        { source_asset: wells[1].uuid, target_asset: child.wells[1].uuid, outer_request: new_requests[1].uuid },
        { source_asset: wells[2].uuid, target_asset: child.wells[2].uuid, outer_request: new_requests[2].uuid }
      ]
    end

    it_behaves_like 'it has a custom page', 'well_filtered_tagged_plate'

    it 'creates a tag plate with the right requests' do
      expect_plate_conversion_creation
      expect_state_change_creation
      expect_tag_layout_creation
      expect_transfer_request_collection_creation

      expect(subject.save).to be true
    end
  end
end
