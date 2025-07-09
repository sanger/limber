# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Uses a custom transfer template to transfer material into the new plate
RSpec.describe LabwareCreators::StampedPlate do
  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }
  let(:plate) do
    create :v2_stock_plate, uuid: parent_uuid, barcode_number: '2', size: plate_size, outer_requests: requests
  end
  let(:child_plate) do
    create :v2_plate, uuid: 'child-uuid', barcode_number: '3', size: plate_size, outer_requests: requests
  end
  let(:requests) { Array.new(plate_size) { |i| create :library_request, state: 'started', uuid: "request-#{i}" } }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  before do
    create(:purpose_config, name: child_purpose_name, uuid: child_purpose_uuid)
    stub_v2_plate(child_plate, stub_search: false)
    stub_v2_plate(plate, stub_search: false)
  end

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a described_class
    end
  end

  shared_examples 'a stamped plate creator' do
    describe '#save!' do
      let(:plate_creations_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }

      it 'makes the expected requests' do
        expect_plate_creation
        expect_transfer_request_collection_creation

        expect(subject.save!).to be true
      end
    end
  end

  context '96 well plate' do
    let(:plate_size) { 96 }

    let(:transfer_requests_attributes) do
      WellHelpers
        .column_order(plate_size)
        .each_with_index
        .map do |well_name, index|
          {
            source_asset: "2-well-#{well_name}",
            target_asset: "3-well-#{well_name}",
            outer_request: "request-#{index}"
          }
        end
    end

    it_behaves_like 'a stamped plate creator'
  end

  context '384 well plate' do
    let(:plate_size) { 384 }

    let(:transfer_requests_attributes) do
      WellHelpers
        .column_order(plate_size)
        .each_with_index
        .map do |well_name, index|
          {
            source_asset: "2-well-#{well_name}",
            target_asset: "3-well-#{well_name}",
            outer_request: "request-#{index}"
          }
        end
    end

    it_behaves_like 'a stamped plate creator'
  end

  context 'more complicated scenarios' do
    let(:plate) { create :v2_plate, uuid: parent_uuid, barcode_number: '2', wells: wells }

    context 'with multiple requests of different types' do
      let(:request_type_a) { create :request_type, key: 'rt_a' }
      let(:request_type_b) { create :request_type, key: 'rt_b' }
      let(:request_a) { create :library_request, request_type: request_type_a, uuid: 'request-a' }
      let(:request_b) { create :library_request, request_type: request_type_b, uuid: 'request-b' }
      let(:request_c) { create :library_request, request_type: request_type_a, uuid: 'request-c' }
      let(:request_d) { create :library_request, request_type: request_type_b, uuid: 'request-d' }
      let(:wells) do
        [
          create(
            :v2_stock_well,
            uuid: '2-well-A1',
            location: 'A1',
            aliquot_count: 1,
            requests_as_source: [request_a, request_b]
          ),
          create(
            :v2_stock_well,
            uuid: '2-well-B1',
            location: 'B1',
            aliquot_count: 1,
            requests_as_source: [request_c, request_d]
          ),
          create(:v2_stock_well, uuid: '2-well-c1', location: 'C1', aliquot_count: 0, requests_as_source: [])
        ]
      end
      let(:transfer_requests_attributes) do
        [
          { source_asset: '2-well-A1', target_asset: '3-well-A1', outer_request: 'request-b' },
          { source_asset: '2-well-B1', target_asset: '3-well-B1', outer_request: 'request-d' }
        ]
      end

      context 'when a request_type is supplied' do
        let(:form_attributes) do
          {
            purpose_uuid: child_purpose_uuid,
            parent_uuid: parent_uuid,
            user_uuid: user_uuid,
            filters: {
              request_type_key: [request_type_b.key]
            }
          }
        end

        it_behaves_like 'a stamped plate creator'
      end

      context 'when a request_type is not supplied' do
        let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

        it 'raises an exception' do
          expect { subject.save! }.to raise_error(LabwareCreators::ResourceInvalid)
        end
      end

      context 'when using library type filter' do
        let(:lib_type_a) { 'LibTypeA' }
        let(:request_b) do
          create :library_request, request_type: request_type_b, uuid: 'request-b', library_type: lib_type_a
        end
        let(:request_d) do
          create :library_request, request_type: request_type_b, uuid: 'request-d', library_type: lib_type_a
        end

        context 'when a library type is supplied' do
          let(:form_attributes) do
            {
              purpose_uuid: child_purpose_uuid,
              parent_uuid: parent_uuid,
              user_uuid: user_uuid,
              filters: {
                library_type: [lib_type_a]
              }
            }
          end

          it_behaves_like 'a stamped plate creator'
        end

        context 'when both request and library types are supplied' do
          let(:form_attributes) do
            {
              purpose_uuid: child_purpose_uuid,
              parent_uuid: parent_uuid,
              user_uuid: user_uuid,
              filters: {
                request_type_key: [request_type_b.key],
                library_type: [lib_type_a]
              }
            }
          end

          it_behaves_like 'a stamped plate creator'
        end

        context 'when a library type is supplied that does not match any request' do
          let(:form_attributes) do
            {
              purpose_uuid: child_purpose_uuid,
              parent_uuid: parent_uuid,
              user_uuid: user_uuid,
              filters: {
                library_type: ['LibTypeB']
              }
            }
          end

          it 'raises an exception' do
            expect { subject.save! }.to raise_error(LabwareCreators::ResourceInvalid)
          end
        end
      end
    end

    context 'such as the ISC pipeline post pooling' do
      # Here we have multiple aliquots in the source well, which all need to be transferred
      # We don't specify an outer request, and Sequencescape should just move the aliquots across
      # as normal.
      let(:request_type) { create :request_type, key: 'rt_a' }
      let(:request_a) { create :library_request, request_type: request_type, uuid: 'request-a', submission_id: '2' }
      let(:request_b) { create :library_request, request_type: request_type, uuid: 'request-b', submission_id: '2' }
      let(:request_c) { create :library_request, request_type: request_type, uuid: 'request-c', submission_id: '2' }
      let(:request_d) { create :library_request, request_type: request_type, uuid: 'request-d', submission_id: '2' }
      let(:aliquots_a) do
        [
          create(:v2_aliquot, library_state: 'started', outer_request: request_a),
          create(:v2_aliquot, library_state: 'started', outer_request: request_b)
        ]
      end
      let(:aliquots_b) do
        [
          create(:v2_aliquot, library_state: 'started', outer_request: request_c),
          create(:v2_aliquot, library_state: 'started', outer_request: request_d)
        ]
      end

      let(:wells) do
        [
          create(:v2_well, uuid: '2-well-A1', location: 'A1', aliquots: aliquots_a),
          create(:v2_well, uuid: '2-well-B1', location: 'B1', aliquots: aliquots_b)
        ]
      end

      context 'when a request_type is supplied' do
        let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

        let(:transfer_requests_attributes) do
          [
            { source_asset: '2-well-A1', target_asset: '3-well-A1', submission_id: '2' },
            { source_asset: '2-well-B1', target_asset: '3-well-B1', submission_id: '2' }
          ]
        end

        it_behaves_like 'a stamped plate creator'
      end
    end
  end
end
