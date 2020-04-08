# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative '../../support/shared_tagging_examples'
require_relative 'shared_examples'

# Uses a custom transfer template to transfer material into the new plate
RSpec.describe LabwareCreators::MergedPlate do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has a custom page', 'merged_plate'

  has_a_working_api

  subject do
    LabwareCreators::MergedPlate.new(api, form_attributes)
  end

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }

  let(:plate_includes) { 'purpose,parents,wells.aliquots.request,wells.requests_as_source' }

  let(:shared_parent) { create :v2_plate }
  let(:source_plate_1) { create :v2_plate, barcode_number: '2', size: plate_size, outer_requests: requests, parent: shared_parent }
  let(:source_plate_2) { create :v2_plate, barcode_number: '3', size: plate_size, outer_requests: requests, parent: shared_parent }

  let(:child_plate) { create :v2_plate, uuid: 'child-uuid', barcode_number: '4', size: plate_size, outer_requests: requests }

  let(:requests) { Array.new(plate_size) { |i| create :library_request, state: 'started', uuid: "request-#{i}", submission_id: 1 } }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  before do
    create(:purpose_config, name: child_purpose_name, uuid: child_purpose_uuid, creator_class: 'LabwareCreators::MergedPlate')
    stub_v2_plate(child_plate, stub_search: false)
    stub_v2_plate(source_plate_1, stub_search: false)
    stub_v2_plate(source_plate_2, stub_search: false)
  end

  let(:form_attributes) do
    {
      purpose_uuid: child_purpose_uuid,
      parent_uuid: source_plate_1.uuid,
      user_uuid: user_uuid
    }
  end

  shared_examples 'a merged plate creator' do
    describe '#save!' do
      before do
        allow(Sequencescape::Api::V2::Plate).to(
          receive(:find_all)
            .with({ barcode: [source_plate_1.barcode.machine, source_plate_2.barcode.machine] }, includes: plate_includes)
            .and_return([source_plate_1, source_plate_2])
        )
      end

      let!(:plate_creation_request) do
        stub_api_post(
          'pooled_plate_creations',
          payload: {
            pooled_plate_creation: {
              user: user_uuid,
              child_purpose: child_purpose_uuid,
              parents: [source_plate_1.uuid, source_plate_2.uuid]
            }
          },
          body: json(:plate_creation, child_uuid: child_plate.uuid)
        )
      end

      let!(:transfer_creation_request) do
        stub_api_post('transfer_request_collections',
                      payload: { transfer_request_collection: {
                        user: user_uuid,
                        transfer_requests: transfer_requests
                      } },
                      body: '{}')
      end

      it 'makes the expected requests' do
        expect(subject.valid?).to eq true
        expect(subject.save!).to eq true
        expect(plate_creation_request).to have_been_made
        expect(transfer_creation_request).to have_been_made
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

    let(:transfer_requests) do
      WellHelpers.column_order(plate_size).each_with_index.map do |well_name, _index|
        {
          'source_asset' => "2-well-#{well_name}",
          'target_asset' => "4-well-#{well_name}",
          'submission_id' => '1'
        }
      end.concat(
        WellHelpers.column_order(plate_size).each_with_index.map do |well_name, _index|
          {
            'source_asset' => "3-well-#{well_name}",
            'target_asset' => "4-well-#{well_name}",
            'submission_id' => '1'
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

  context 'with a mismatched pair of source plates' do
    let(:different_requests) { Array.new(plate_size) { |i| create :library_request, state: 'started', uuid: "request-#{i}", submission_id: 2 } }
    let(:different_parent) { create :v2_plate }
    let(:source_plate_3) { create :v2_plate, barcode_number: '4', size: plate_size, outer_requests: different_requests, parent: different_parent }

    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent_uuid,
        user_uuid: user_uuid,
        barcodes: [source_plate_1.barcode.machine, source_plate_3.barcode.machine]
      }
    end

    before do
      create(:purpose_config, name: child_purpose_name, uuid: child_purpose_uuid, creator_class: 'LabwareCreators::MergedPlate')
      stub_v2_plate(source_plate_3, stub_search: false)
      allow(Sequencescape::Api::V2::Plate).to(
        receive(:find_all)
          .with({ barcode: [source_plate_1.barcode.machine, source_plate_3.barcode.machine] }, includes: plate_includes)
          .and_return([source_plate_1, source_plate_3])
      )
    end

    it 'is invalid' do
      expect(subject.valid?).to eq false
    end
  end
end
