# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::StampedPlateReorderingColumnsToRows do
  subject { described_class.new(form_attributes) }

  let(:user_uuid) { 'user-uuid' }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:parent_uuid) { 'parent-uuid' }

  let(:parent_wells) do
    locations = WellHelpers.column_order(96, rows: 8, columns: 12)
    locations.take(8).map { |location| create(:well, location: location, aliquot_count: 2, state: 'passed') }
  end

  let(:parent) { create(:plate, size: 96, uuid: parent_uuid, wells: parent_wells) }

  let(:child_wells) do
    locations = WellHelpers.row_order(8, rows: 1, columns: 8)
    locations.take(8).map { |location| create(:well, location: location, aliquot_count: 0) }
  end

  let(:child_uuid) { 'child-uuid' }

  let(:child_plate) do
    create(:plate, size: 8, number_of_rows: 1, number_of_columns: 8, wells: child_wells, uuid: child_uuid)
  end

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  before do
    # Create the purpose config to be able to test the validation for number of source wells.
    create(:purpose_config, uuid: child_purpose_uuid, name: child_purpose_name, size: 8)

    allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(uuid: parent_uuid).and_return(parent)
    allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(uuid: child_uuid).and_return(child_plate)
  end

  describe '#labware_wells' do
    it 'returns the parent wells in column order' do
      expect(subject.labware_wells).to eq(parent.wells_in_columns)
    end
  end

  describe '#request_hash' do
    it 'returns request hash by reordering columns to rows' do
      parent.wells_in_columns.each_with_index do |source_well, index|
        submission_id = source_well.aliquots.first.request.submission_id # Same for all aliquots in the well
        additional_parameters = { submission_id: }

        request_hash = subject.request_hash(source_well, child_plate, additional_parameters)

        expect(request_hash[:source_asset]).to eq(source_well.uuid)
        expect(request_hash[:target_asset]).to eq(child_plate.wells_in_rows[index].uuid)
        expect(request_hash[:submission_id]).to eq(submission_id)
      end
    end
  end

  describe '#save!' do
    # Expected plate creation attributes
    let(:plate_creations_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }

    # Expected transferred source wells
    let(:transferred_wells) { parent_wells }

    # Expected transfer requests from source wells to child wells
    let(:transfer_requests_attributes) do
      transferred_wells.map.with_index do |source_well, index|
        # p "#{source_well.location} -> #{child_plate.wells_in_rows[index].location}"
        submission_id = source_well.aliquots.first.request.submission_id
        {
          source_asset: source_well.uuid,
          target_asset: child_plate.wells_in_rows[index].uuid,
          submission_id: submission_id
        }
      end
    end

    context 'with all source wells' do
      it 'creates transfer requests by ordering columns to rows' do
        # A1 -> A1, B1 -> A2, C1 -> A3, D1 -> A4, E1 -> A5, F1 -> A6, G1 -> A7, H1 -> A8
        expect_plate_creation
        expect_transfer_request_collection_creation

        subject.save!
      end
    end

    context 'with some source wells failed' do
      let(:transferred_wells) do
        # Fail 1st, 5th, and last wells
        failed_wells = [parent_wells[0], parent_wells[4], parent_wells[-1]]
        failed_wells.each { |well| well.state = 'failed' }
        parent_wells - failed_wells # Exclude the failed wells
      end

      it 'compresses the wells in the child plate' do
        # B1 -> A1, C1 -> A2, D1 -> A3, F1 -> A4, G1 -> A5
        expect_plate_creation
        expect_transfer_request_collection_creation

        subject.save!
      end
    end
  end

  describe '#valid?' do
    describe '#source_wells_must_fit_child_plate' do
      it 'is valid when all source wells fit the child plate' do
        expect(subject).to be_valid
      end

      context 'when there are more source wells than the child plate size' do
        let(:parent_wells) do
          locations = WellHelpers.column_order(96, rows: 8, columns: 12)
          locations.take(9).map { |location| create(:well, location: location, aliquot_count: 2, state: 'passed') }
        end

        it 'reports the error' do
          expect(subject).not_to be_valid
          formatted_string =
            format(described_class::SOURCE_WELLS_MUST_FIT_CHILD_PLATE, parent_wells.size, child_plate.size)
          expect(subject.errors[:source_plate]).to include(formatted_string)
        end
      end
    end
  end
end
