# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::TubesFromPlateWell do
  has_a_working_api

  context 'for pre creation' do
    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a plate' do
        let(:parent) { build :plate }

        it { is_expected.to be true }
      end
    end
  end

  context 'for creation' do
    subject { described_class.new(api, form_attributes) }

    let(:controller) { TubeCreationController.new }
    let(:child_purpose_uuid) { SecureRandom.uuid }
    let(:parent_uuid) { SecureRandom.uuid }
    let(:user_uuid) { SecureRandom.uuid }
    let(:parent_purpose_name) { 'Parent Purpose 1' }
    let(:parent_purpose_uuid) { 'parent-purpose-uuid' }
    let(:request_type_first) { create(:request_type, key: 'request-type-1') }
    let(:library_type_first) { 'library-type-1' }
    let(:new_submission) { create(:v2_submission) }
    let(:new_requests) do
      [
        create(
          :request,
          :uuid,
          request_type: request_type_first,
          library_type: library_type_first,
          state: 'pending',
          submission: new_submission
        )
      ]
    end
    let(:old_requests) do
      [create(:request, :uuid, request_type: request_type_first, library_type: library_type_first, state: 'pending')]
    end
    let(:aliquots) { [create(:v2_aliquot, request: [old_requests[0]])] }
    let(:wells) { [create(:v2_well, requests_as_source: [new_requests[0]], aliquots: [aliquots[0]], location: 'A1')] }
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
    let(:child_tubes) { create_list(:tube, 2) }
    let(:transfer_template_uuid) { 'transfer-between-specific-tubes' } # Defined in spec_helper.rb

    let(:transfers_attributes) do
      [
        {
          arguments: {
            user_uuid: user_uuid,
            source_uuid: parent_uuid,
            destination_uuid: child_tubes.first&.uuid,
            transfer_template_uuid: transfer_template_uuid
          }
        }
      ]
    end

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }
    let(:tubes_from_plate_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }
    let(:transfer_requests_attributes) { [{ source_asset: wells[0].uuid, target_asset: child_tubes.first&.uuid }] }

    it_behaves_like 'it has no custom page'

    describe '#save!' do
      before do
        stub_v2_plate(parent)
        allow(Sequencescape::Api::V2::TubeFromPlateCreation).to receive(:create!).and_return(
          instance_double(Sequencescape::Api::V2::TubeFromPlateCreation, child: child_tubes.first)
        )
        allow(Sequencescape::Api::V2::TransferRequestCollection).to receive(:create!).and_return(
          instance_double(Sequencescape::Api::V2::TransferRequestCollection, target_tubes: [child_tubes.first])
        )
      end

      it 'creates the child tubes' do
        # expect_tubes_from_tube_creation
        expect_transfer_request_collection_creation

        subject.save!
      end
    end
  end
end
