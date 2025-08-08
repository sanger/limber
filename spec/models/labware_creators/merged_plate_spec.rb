# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Uses a custom transfer template to transfer material into the new plate
RSpec.describe LabwareCreators::MergedPlate do
  subject { described_class.new(api, form_attributes) }

  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has a custom page', 'merged_plate'

  has_a_working_api

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }

  let(:plate_includes) { 'purpose,parents,wells.aliquots.request,wells.requests_as_source' }

  let(:source_purpose_1_uuid) { 'source-1-purpose' }
  let(:source_purpose_1_name) { 'Source 1 Purpose' }
  let(:source_purpose_1) { create :purpose_config, name: source_purpose_1_name, uuid: source_purpose_1_uuid }

  let(:source_purpose_2_uuid) { 'source-2-purpose' }
  let(:source_purpose_2_name) { 'Source 2 Purpose' }
  let(:source_purpose_2) { create :purpose_config, name: source_purpose_2_name, uuid: source_purpose_2_uuid }

  let(:shared_parent) { create :v2_plate, barcode_number: '1', size: plate_size }
  let(:source_plate_1) do
    create :v2_plate,
           barcode_number: '2',
           size: plate_size,
           outer_requests: requests,
           parents: [shared_parent],
           purpose: source_purpose_1
  end
  let(:source_plate_2) do
    create :v2_plate,
           barcode_number: '3',
           size: plate_size,
           outer_requests: requests,
           parents: [shared_parent],
           purpose: source_purpose_2
  end

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }
  let(:child_purpose) do
    create :merged_plate_purpose_config,
           name: child_purpose_name,
           uuid: child_purpose_uuid,
           creator_class: 'LabwareCreators::MergedPlate'
  end

  let(:requests) do
    Array.new(plate_size) { |i| create :library_request, state: 'started', uuid: "request-#{i}", submission_id: 1 }
  end

  let(:user_uuid) { 'user-uuid' }

  before do
    stub_v2_plate(source_plate_1, stub_search: false)
    stub_v2_plate(source_plate_2, stub_search: false)
  end

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: source_plate_1.uuid, user_uuid: user_uuid } }

  shared_examples 'a merged plate creator' do
    describe '#save!' do
      before do
        allow(Sequencescape::Api::V2::Plate).to(
          receive(:find_all).with(
            { barcode: [source_plate_1.barcode.machine, source_plate_2.barcode.machine] },
            includes: plate_includes
          ).and_return([source_plate_1, source_plate_2])
        )

        stub_v2_plate(child_plate, stub_search: false)
      end

      let(:child_plate) do
        create :v2_plate,
               uuid: 'child-uuid',
               barcode_number: '4',
               size: plate_size,
               outer_requests: requests,
               purpose: child_purpose
      end

      let(:pooled_plates_attributes) do
        [
          {
            child_purpose_uuid: child_purpose_uuid,
            parent_uuids: [source_plate_1.uuid, source_plate_2.uuid],
            user_uuid: user_uuid
          }
        ]
      end

      it 'makes the expected requests' do
        expect_pooled_plate_creation
        expect_transfer_request_collection_creation

        expect(subject).to be_valid
        expect(subject.save!).to be true
      end
    end
  end

  context 'on create' do
    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent_uuid,
        user_uuid: user_uuid,
        barcodes: [source_plate_1.barcode.machine, source_plate_2.barcode.machine]
      }
    end

    let(:transfer_requests_attributes) do
      WellHelpers
        .column_order(plate_size)
        .each_with_index
        .map do |well_name, _index|
          {
            source_asset: "2-well-#{well_name}",
            target_asset: "4-well-#{well_name}",
            submission_id: '1',
            merge_equivalent_aliquots: true
          }
        end
        .concat(
          WellHelpers
            .column_order(plate_size)
            .each_with_index
            .map do |well_name, _index|
              {
                source_asset: "3-well-#{well_name}",
                target_asset: "4-well-#{well_name}",
                submission_id: '1',
                merge_equivalent_aliquots: true
              }
            end
        )
    end

    context '96 well plate' do
      let(:plate_size) { 96 }

      it_behaves_like 'a merged plate creator'
    end

    context '384 well plate' do
      let(:plate_size) { 384 }

      it_behaves_like 'a merged plate creator'
    end
  end

  context 'with source plates from different parents and requests' do
    let(:different_requests) do
      Array.new(plate_size) { |i| create :library_request, state: 'started', uuid: "request-#{i}", submission_id: 2 }
    end
    let(:different_parent) { create :v2_plate }
    let(:source_plate_3) do
      create :v2_plate,
             barcode_number: '4',
             size: plate_size,
             outer_requests: different_requests,
             parents: [different_parent],
             purpose: source_purpose_2
    end

    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent_uuid,
        user_uuid: user_uuid,
        barcodes: [source_plate_1.barcode.machine, source_plate_3.barcode.machine]
      }
    end

    before do
      create(
        :merged_plate_purpose_config,
        name: child_purpose_name,
        uuid: child_purpose_uuid,
        creator_class: 'LabwareCreators::MergedPlate',
        source_purposes: ['Source 1 Purpose', 'Source 2 Purpose']
      )
      stub_v2_plate(source_plate_3, stub_search: false)
      allow(Sequencescape::Api::V2::Plate).to(
        receive(:find_all).with(
          { barcode: [source_plate_1.barcode.machine, source_plate_3.barcode.machine] },
          includes: plate_includes
        ).and_return([source_plate_1, source_plate_3])
      )
    end

    it { is_expected.not_to be_valid }
  end

  context 'with source plates from different parents but same requests' do
    let(:different_parent) { create :v2_plate }
    let(:source_plate_3) do
      create :v2_plate,
             barcode_number: '4',
             size: plate_size,
             outer_requests: requests,
             parents: [different_parent],
             purpose: source_purpose_2
    end

    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent_uuid,
        user_uuid: user_uuid,
        barcodes: [source_plate_1.barcode.machine, source_plate_3.barcode.machine]
      }
    end

    before do
      create(
        :merged_plate_purpose_config,
        name: child_purpose_name,
        uuid: child_purpose_uuid,
        creator_class: 'LabwareCreators::MergedPlate',
        source_purposes: ['Source 1 Purpose', 'Source 2 Purpose']
      )
      stub_v2_plate(source_plate_3, stub_search: false)
      allow(Sequencescape::Api::V2::Plate).to(
        receive(:find_all).with(
          { barcode: [source_plate_1.barcode.machine, source_plate_3.barcode.machine] },
          includes: plate_includes
        ).and_return([source_plate_1, source_plate_3])
      )
    end

    it { is_expected.to be_valid }
  end

  context 'with a missing barcode' do
    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent_uuid,
        user_uuid: user_uuid,
        barcodes: [source_plate_1.barcode.machine, '']
      }
    end

    before do
      create(
        :merged_plate_purpose_config,
        name: child_purpose_name,
        uuid: child_purpose_uuid,
        creator_class: 'LabwareCreators::MergedPlate',
        source_purposes: ['Source 1 Purpose', 'Source 2 Purpose']
      )
      allow(Sequencescape::Api::V2::Plate).to(
        receive(:find_all).with({ barcode: [source_plate_1.barcode.machine] }, includes: plate_includes).and_return(
          [source_plate_1]
        )
      )
    end

    it 'is invalid' do
      expect(subject.valid?).to be false
    end
  end

  context 'with the same barcode scanned multiple times' do
    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent_uuid,
        user_uuid: user_uuid,
        barcodes: [source_plate_1.barcode.machine, source_plate_1.barcode.machine]
      }
    end

    before do
      create(
        :merged_plate_purpose_config,
        name: child_purpose_name,
        uuid: child_purpose_uuid,
        creator_class: 'LabwareCreators::MergedPlate',
        source_purposes: ['Source 1 Purpose', 'Source 2 Purpose']
      )
      allow(Sequencescape::Api::V2::Plate).to(
        receive(:find_all).with(
          { barcode: [source_plate_1.barcode.machine, source_plate_1.barcode.machine] },
          includes: plate_includes
        ).and_return([source_plate_1])
      )
    end

    it 'is invalid' do
      expect(subject.valid?).to be false
    end
  end

  # check for user accidently making 2 plates of the same purpose type that they then try to merge
  context 'with two plates of the same purpose and same parent' do
    let(:source_plate_4) do
      create :v2_plate,
             barcode_number: '5',
             size: plate_size,
             outer_requests: requests,
             parents: [shared_parent],
             purpose: source_purpose_1
    end

    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent_uuid,
        user_uuid: user_uuid,
        barcodes: [source_plate_1.barcode.machine, source_plate_4.barcode.machine]
      }
    end

    before do
      create(
        :merged_plate_purpose_config,
        name: child_purpose_name,
        uuid: child_purpose_uuid,
        creator_class: 'LabwareCreators::MergedPlate',
        source_purposes: ['Source 1 Purpose', 'Source 2 Purpose']
      )
      allow(Sequencescape::Api::V2::Plate).to(
        receive(:find_all).with(
          { barcode: [source_plate_1.barcode.machine, source_plate_4.barcode.machine] },
          includes: plate_includes
        ).and_return([source_plate_1, source_plate_4])
      )
    end

    it 'is invalid' do
      expect(subject.valid?).to be false
    end
  end
end
