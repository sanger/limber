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

    let(:child_plate) { create :plate }

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

    context 'when the bulk transfer fails validation' do
      let(:error_message) do
        "Aliquot::TagClash: SQPD-9395:E1 contains aliquots which can't be transferred due to tag clash"
      end
      let(:bulk_transfer) { Sequencescape::Api::V2::BulkTransfer.new }
      let(:api_errors) do
        JsonApiClient::ErrorCollector.new([{ title: 'Tag clash', detail: error_message }])
      end
      let(:result_set) { JsonApiClient::ResultSet.new.tap { |set| set.errors = api_errors } }

      before do
        expect_pooled_plate_creation
        bulk_transfer.errors.add(:base, 'Tag clash')
        allow(bulk_transfer).to receive(:last_result_set).and_return(result_set)
        allow(Sequencescape::Api::V2::BulkTransfer).to receive(:create!).and_raise(
          JsonApiClient::Errors::RecordNotSaved.new('Transfer failed', bulk_transfer)
        )
      end

      it 'returns false and exposes the API message to the creation failure handler', :aggregate_failures do
        expect(subject.save).to be(false)
        expect(subject.errors.full_messages).to eq([error_message])
      end

      it 'raises a resource error containing the API message when saved with a bang' do
        expect { subject.save! }.to raise_error(LabwareCreators::ResourceInvalid, error_message)
      end
    end

    context 'when the bulk transfer has an unexpected server error' do
      before do
        expect_pooled_plate_creation
        allow(Sequencescape::Api::V2::BulkTransfer).to receive(:create!).and_raise(
          JsonApiClient::Errors::InternalServerError.new(Faraday::Env.new(status: 500))
        )
      end

      it 'does not treat the server error as a validation failure' do
        expect { subject.save }.to raise_error(JsonApiClient::Errors::InternalServerError)
      end
    end

    context 'with active requests on parent plates' do
      let(:plate) { create(:plate) }
      let(:plate_b) { create(:plate) }
      let(:request_type_isc) { create(:request_type, key: 'limber_bge_isc', name: 'Limber BGE ISC') }
      let(:request_type_transition) do
        create(:request_type, key: 'limber_bge_transition', name: 'Limber BGE Transition')
      end
      let(:request_isc) { create(:request, request_type: request_type_isc) }
      let(:request_b_isc) { create(:request, request_type: request_type_isc) }
      let(:request_transition) { create(:request, request_type: request_type_transition) }

      before do
        # Override the purpose config to set allowed active requests.
        create(:purpose_config,
               name: child_purpose_name,
               uuid: child_purpose_uuid,
               creator_class: {
                 args: {
                   allowed_active_requests: [
                     'limber_bge_isc'
                   ]
                 }
               })

        allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with({ uuid: plate_uuid }).and_return(plate)
        allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with({ uuid: plate_b_uuid }).and_return(plate_b)
      end

      context 'when a parent has an active request not allowed' do
        before do
          allow(Sequencescape::Api::V2::PooledPlateCreation).to receive(:create!) # to spy on it
          allow(plate).to receive(:active_requests).and_return([request_isc, request_transition])
          allow(plate_b).to receive(:active_requests).and_return([request_b_isc])
        end

        it 'does not create child labware' do
          subject.save # The creation controller calls save.
          expect(Sequencescape::Api::V2::PooledPlateCreation).not_to have_received(:create!) # spied
        end

        it 'adds an error about the active request' do
          subject.save
          expect(subject.errors.full_messages).to include(
            I18n.t('errors.messages.request_needs_closing',
                   request_type_name: request_type_transition.name,
                   parent_barcode: plate.human_barcode,
                   purpose_name: child_purpose_name)
          )
        end
      end

      context 'when all parents have only allowed active requests' do
        before do
          allow(plate).to receive(:active_requests).and_return([request_isc])
          allow(plate_b).to receive(:active_requests).and_return([request_b_isc])
        end

        it 'creates the child labware' do
          expect_bulk_transfer_creation
          expect_pooled_plate_creation
          subject.save
        end

        it 'does not add any errors' do
          expect_bulk_transfer_creation
          expect_pooled_plate_creation
          subject.save
          expect(subject.errors).to be_empty
        end
      end

      context 'when allowed_active_requests is empty' do
        before do
          create(:purpose_config,
                 name: child_purpose_name,
                 uuid: child_purpose_uuid,
                 creator_class: {
                   args: {
                     allowed_active_requests: [nil, ''] # to test rejecting blank values as well.
                   }
                 })
        end

        it 'creates the child labware' do
          expect_bulk_transfer_creation
          expect_pooled_plate_creation
          subject.save
        end

        it 'does not add any errors' do
          expect_bulk_transfer_creation
          expect_pooled_plate_creation
          subject.save
          expect(subject.errors).to be_empty
        end
      end
    end
  end
end
