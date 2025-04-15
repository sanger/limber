# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# # Up to 96 tubes are transferred onto a single 96-well plate.
RSpec.describe LabwareCreators::PlateWithAutoSubmission do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  has_a_working_api

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }
  let(:parent) do
    create :v2_stock_plate, uuid: parent_uuid, barcode_number: '1', size: plate_size, outer_requests: requests
  end
  let(:child_plate) do
    create :v2_plate, uuid: 'child-uuid', barcode_number: '3', size: plate_size, outer_requests: requests
  end
  let(:requests) { Array.new(plate_size) { |i| create :library_request, state: 'started', uuid: "request-#{i}" } }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let!(:purpose_config) do
    create :plate_with_auto_submission_purpose_config, name: child_purpose_name, uuid: child_purpose_uuid
  end

  let(:example_template_uuid) { SecureRandom.uuid }

  before do
    Settings.submission_templates = { 'example' => example_template_uuid }
    stub_v2_plate(child_plate, stub_search: false)
    stub_v2_plate(parent, stub_search: false)
  end

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  subject { LabwareCreators::PlateWithAutoSubmission.new(api, form_attributes) }

  let(:plate_creations_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }
  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a LabwareCreators::PlateWithAutoSubmission
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_purpose_uuid)
    end
  end

  context 'on create' do
    context 'when the submission is created' do
      describe 'internal methods' do
        it 'determines the configuration for the submission' do
          expect(subject.send(:configured_params)).to eq(
            {
              'allowed_extra_barcodes' => false,
              'request_options' => {
                'library_type' => 'example_library'
              },
              'template_name' => 'example'
            }
          )
        end

        context 'if there is more than one configuration' do
          let!(:purpose_config) do
            create :plate_with_auto_submission_purpose_configs, name: child_purpose_name, uuid: child_purpose_uuid
          end
          it 'adds an error' do
            subject.send(:configured_params)
            expect(subject.errors.full_messages).to include('Expected only one submission')
          end
        end

        describe '#autodetect_studies' do
          it 'returns true when specified in the config' do
            expect(subject).to receive(:configured_params).and_return({ autodetect_studies: true, request_options: {} })
            expect(subject.send(:autodetect_studies)).to eq(true)
          end
          it 'returns false when specified in the config' do
            expect(subject).to receive(:configured_params).and_return(
              { autodetect_studies: false, request_options: {} }
            )
            expect(subject.send(:autodetect_studies)).to eq(false)
          end
          it 'returns false if not specified in the config' do
            expect(subject).to receive(:configured_params).and_return({ request_options: {} })
            expect(subject.send(:autodetect_studies)).to eq(false)
          end
        end

        describe '#autodetect_projects' do
          it 'returns true when specified in the config' do
            expect(subject).to receive(:configured_params).and_return(
              { autodetect_projects: true, request_options: {} }
            )
            expect(subject.send(:autodetect_projects)).to eq(true)
          end
          it 'returns false when specified in the config' do
            expect(subject).to receive(:configured_params).and_return(
              { autodetect_projects: false, request_options: {} }
            )
            expect(subject.send(:autodetect_projects)).to eq(false)
          end
          it 'returns false if not specified in the config' do
            expect(subject).to receive(:configured_params).and_return({ request_options: {} })
            expect(subject.send(:autodetect_projects)).to eq(false)
          end
        end
      end
    end
    context '#save!' do
      setup do
        expect(subject).to receive(:parent_uuid).at_least(:once).and_return(parent_uuid)
        expect(subject).to receive(:purpose_uuid).at_least(:once).and_return(child_purpose_uuid)
      end

      let!(:submission_submit) { stub_api_post('sub-uuid', 'submit') }
      let(:transfer_requests_attributes) do
        [hash_including(source_asset: 'example-well1-uuid', target_asset: '3-well-A1')]
      end

      context 'when saving the plate' do
        setup { expect('Sequencescape::Api::V2::Submission'.constantize).to receive(:where).and_return([submission]) }

        # set up two tube to plate well transfers, each from a different study
        let(:aliquot1) { create :v2_aliquot, study_id: 1 }

        let(:well1_uuid) { 'example-well1-uuid' }
        let(:parent_well_uuids) { [well1_uuid] }

        let(:wells) { [create(:v2_well, location: 'A1', aliquots: [aliquot1], uuid: well1_uuid)] }

        let(:parent) do
          create :v2_stock_plate,
                 purpose_uuid: 'parent-plate-purpose-uuid',
                 uuid: parent_uuid,
                 barcode_number: '1',
                 size: plate_size,
                 outer_requests: requests,
                 wells: wells
        end

        let!(:order_request) do
          stub_api_get(example_template_uuid, body: json(:submission_template, uuid: example_template_uuid))
          stub_api_post(
            example_template_uuid,
            'orders',
            payload: {
              order: {
                assets: ['example-well1-uuid'],
                request_options: purpose_config[:submission_options]['scRNA library prep']['request_options'],
                user: user_uuid,
                autodetect_studies: true,
                autodetect_projects: true
              }
            },
            body: '{"order":{"uuid":"order-uuid"}}'
          )
        end

        let!(:submission_request) do
          stub_api_post(
            'submissions',
            payload: {
              submission: {
                orders: ['order-uuid'],
                user: user_uuid
              }
            },
            body: json(:submission, uuid: 'sub-uuid', orders: [{ uuid: 'order-uuid' }])
          )
        end

        let!(:submission) do
          create(:v2_submission, uuid: 'sub-uuid', orders: [{ uuid: 'order-uuid' }, { uuid: 'order-2-uuid' }])
        end

        it 'creates a plate!' do
          expect_plate_creation
          expect_transfer_request_collection_creation

          subject.save!

          expect(order_request).to have_been_made.once
          expect(submission_request).to have_been_made.once
          expect(submission_submit).to have_been_made.once
        end
      end
    end
  end
end
