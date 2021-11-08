# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# # Up to 96 tubes are transferred onto a single 96-well plate.
RSpec.describe LabwareCreators::MultiStampTubes do
  it_behaves_like 'it only allows creation from tubes'

  has_a_working_api

  let(:parent1_uuid) { 'example-tube1-uuid' }
  let(:parent2_uuid) { 'example-tube2-uuid' }
  let(:child_uuid) { 'child-uuid' }
  let(:parent1) { create :v2_stock_tube, uuid: parent1_uuid, purpose_uuid: 'parent-tube-purpose-uuid' }
  let(:parent2) { create :v2_stock_tube, uuid: parent2_uuid, purpose_uuid: 'parent-tube-purpose-uuid' }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }
  let(:child_plate_v2) { create :v2_plate_for_submission, uuid: child_uuid, purpose_name: child_purpose_name, barcode_number: '5', size: 96 }
  let(:child_plate_v1) { json :stock_plate_with_metadata, stock_plate: { barcode: '5', uuid: child_uuid } }

  let(:assets) do
    child_plate_v2.wells.map(&:uuid)
  end
  let(:user_uuid) { 'user-uuid' }
  let(:user) { json :v1_user, uuid: user_uuid }

  let(:example_template_uuid) { SecureRandom.uuid }

  let!(:purpose_config) { create :multi_stamp_tubes_purpose_config, name: child_purpose_name, uuid: child_purpose_uuid }

  before do
    Settings.submission_templates = {
      'example' => example_template_uuid
    }
    stub_v2_tube(parent1, stub_search: false)
    stub_v2_tube(parent2, stub_search: false)
    stub_v2_plate(
      child_plate_v2,
      stub_search: false,
      custom_includes: 'wells,wells.aliquots,wells.aliquots.study'
    )
  end

  context 'on new' do
    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: parent1_uuid
      }
    end

    subject do
      LabwareCreators::MultiStampTubes.new(api, form_attributes)
    end

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::MultiStampTubes
    end

    it 'renders the "multi_stamp_tubes" page' do
      expect(subject.page).to eq('multi_stamp_tubes')
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_purpose_uuid)
    end
  end

  context 'on create' do
    subject do
      LabwareCreators::MultiStampTubes.new(api, form_attributes.merge(user_uuid: user_uuid))
    end

    let(:form_attributes) do
      {
        parent_uuid: parent1_uuid,
        purpose_uuid: child_purpose_uuid,
        transfers: [
          { source_tube: parent1_uuid, source_asset: 'tube1', new_target: { location: 'A1' } },
          { source_tube: parent2_uuid, source_asset: 'tube2', new_target: { location: 'B1' } }
        ]
      }
    end

    let!(:ms_plate_creation_request) do
      stub_api_post(
        'pooled_plate_creations',
        payload: {
          pooled_plate_creation: {
            user: user_uuid,
            child_purpose: child_purpose_uuid,
            parents: [parent1_uuid, parent2_uuid]
          }
        },
        body: json(:plate_creation, child_uuid: child_uuid)
      )
    end

    let(:transfer_requests) do
      [
        { source_asset: 'tube1', target_asset: '5-well-A1' },
        { source_asset: 'tube2', target_asset: '5-well-B1' }
      ]
    end

    let!(:transfer_creation_request) do
      stub_api_post('transfer_request_collections',
                    payload: { transfer_request_collection: {
                      user: user_uuid,
                      transfer_requests: transfer_requests
                    } },
                    body: '{}')
    end

    context '#save!' do
      setup do
        stub_api_get(child_plate_v2.uuid, body: child_plate_v1)
        stub_api_get('custom_metadatum_collection-uuid',
                     body: json(:v1_custom_metadatum_collection,
                                uuid: 'custom_metadatum_collection-uuid'))
        stub_api_get('user-uuid', body: user)
        stub_api_get('asset-uuid', body: child_plate_v1)

        metadata = attributes_for(:v1_custom_metadatum_collection)
                   .fetch(:metadata, {})

        stub_api_put('custom_metadatum_collection-uuid',
                     payload: {
                       custom_metadatum_collection: { metadata: metadata }
                     },
                     body: json(:v1_custom_metadatum_collection))
      end

      let!(:submission_submit) do
        stub_api_post('sub-uuid', 'submit')
      end

      context 'when sources are from a single study' do
        let!(:order_request) do
          stub_api_get(example_template_uuid, body: json(:submission_template, uuid: example_template_uuid))
          stub_api_post(example_template_uuid, 'orders',
                        payload: { order: {
                          assets: assets,
                          request_options: purpose_config[:submission_options]['Cardinal library prep']['request_options'],
                          user: user_uuid,
                          autodetect_studies_projects: true
                        } },
                        body: '{"order":{"uuid":"order-uuid"}}')
        end

        let!(:submission_request) do
          stub_api_post('submissions',
                        payload: { submission: { orders: ['order-uuid'], user: user_uuid } },
                        body: json(:submission, uuid: 'sub-uuid', orders: [{ uuid: 'order-uuid' }]))
        end

        it 'creates a plate!' do
          subject.save!
          expect(ms_plate_creation_request).to have_been_made.once
          expect(transfer_creation_request).to have_been_made.once
          expect(order_request).to have_been_made.once
          expect(submission_request).to have_been_made.once
          expect(submission_submit).to have_been_made.once
        end
      end

      context 'when sources are from multiple studies' do
        # set up two tube to plate well transfers, each from a different study
        let(:aliquot1) { create :v2_aliquot, study_id: 1 }
        let(:aliquot2) { create :v2_aliquot, study_id: 2 }
        let(:parent1) { create :v2_stock_tube, uuid: parent1_uuid, purpose_uuid: 'parent-tube-purpose-uuid', aliquots: [aliquot1] }
        let(:parent2) { create :v2_stock_tube, uuid: parent2_uuid, purpose_uuid: 'parent-tube-purpose-uuid', aliquots: [aliquot2] }

        let(:child_aliquot1) { create :v2_aliquot, study_id: 1 }
        let(:child_aliquot2) { create :v2_aliquot, study_id: 2 }
        let(:child_well1) { create :v2_stock_well, location: 'A1', uuid: '5-well-A1', aliquots: [child_aliquot1] }
        let(:child_well2) { create :v2_stock_well, location: 'B1', uuid: '5-well-B1', aliquots: [child_aliquot2] }
        let(:child_plate_v2) do
          create :v2_plate_for_submission, uuid: child_uuid, purpose_name: child_purpose_name, barcode_number: '5', size: 96, wells: [child_well1, child_well2]
        end

        let!(:order_request) do
          stub_api_get(example_template_uuid, body: json(:submission_template, uuid: example_template_uuid))
          stub_api_post(example_template_uuid, 'orders',
                        payload: { order: {
                          assets: [assets[0]],
                          request_options: purpose_config[:submission_options]['Cardinal library prep']['request_options'],
                          user: user_uuid,
                          autodetect_studies_projects: true
                        } },
                        body: '{"order":{"uuid":"order-uuid"}}')
          stub_api_post(example_template_uuid, 'orders',
                        payload: { order: {
                          assets: [assets[1]],
                          request_options: purpose_config[:submission_options]['Cardinal library prep']['request_options'],
                          user: user_uuid,
                          autodetect_studies_projects: true
                        } },
                        body: '{"order":{"uuid":"order-2-uuid"}}')
        end

        let!(:submission_request) do
          stub_api_post('submissions',
                        payload: { submission: { orders: ['order-uuid', 'order-2-uuid'], user: user_uuid } },
                        body: json(:submission, uuid: 'sub-uuid', orders: [
                                     { uuid: 'order-uuid' }, { uuid: 'order-2-uuid' }
                                   ]))
        end

        it 'creates a plate!' do
          subject.save!
          expect(ms_plate_creation_request).to have_been_made.once
          expect(transfer_creation_request).to have_been_made.once
          expect(order_request).to have_been_made.once
          expect(submission_request).to have_been_made.once
          expect(submission_submit).to have_been_made.once
        end
      end
    end
  end
end
