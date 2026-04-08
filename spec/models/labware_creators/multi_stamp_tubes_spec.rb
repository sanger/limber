# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# # Up to 96 tubes are transferred onto a single 96-well plate.
RSpec.describe LabwareCreators::MultiStampTubes do
  it_behaves_like 'it only allows creation from tubes'

  let(:parent1_tube_uuid) { 'example-tube1-uuid' }
  let(:parent2_tube_uuid) { 'example-tube2-uuid' }

  let(:parent1_receptacle_uuid) { 'example-receptacle1-uuid' }
  let(:parent2_receptacle_uuid) { 'example-receptacle2-uuid' }
  let(:parent_receptacle_uuids) { [parent1_receptacle_uuid, parent2_receptacle_uuid] }

  let(:parent1_receptacle) { create(:receptacle, uuid: parent1_receptacle_uuid, qc_results: []) }
  let(:parent2_receptacle) { create(:receptacle, uuid: parent2_receptacle_uuid, qc_results: []) }

  let(:parent1) do
    create :stock_tube,
           uuid: parent1_tube_uuid,
           purpose_uuid: 'parent-tube-purpose-uuid',
           receptacle: parent1_receptacle
  end
  let(:parent2) do
    create :stock_tube,
           uuid: parent2_tube_uuid,
           purpose_uuid: 'parent-tube-purpose-uuid',
           receptacle: parent2_receptacle
  end

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let(:example_template_uuid) { SecureRandom.uuid }

  let!(:purpose_config) { create :multi_stamp_tubes_purpose_config, name: child_purpose_name, uuid: child_purpose_uuid }

  before do
    Settings.submission_templates = { 'example' => example_template_uuid }
    stub_tube(parent1, stub_search: false)
    stub_tube(parent2, stub_search: false)
  end

  context 'on new' do
    subject { described_class.new(form_attributes) }

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent1_tube_uuid } }

    it 'can be created' do
      expect(subject).to be_a described_class
    end

    it 'renders the "multi_stamp_tubes" page' do
      expect(subject.page).to eq('multi_stamp_tubes')
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_purpose_uuid)
    end
  end

  context 'on create' do
    subject { described_class.new(form_attributes.merge(user_uuid:)) }

    let(:form_attributes) do
      {
        parent_uuid: parent1_tube_uuid,
        purpose_uuid: child_purpose_uuid,
        transfers: [
          { source_tube: parent1_tube_uuid, source_asset: 'tube1', new_target: { location: 'A1' } },
          { source_tube: parent2_tube_uuid, source_asset: 'tube2', new_target: { location: 'B1' } }
        ]
      }
    end

    let(:transfer_requests_attributes) do
      [
        { source_asset: 'tube1', target_asset: '5-well-A1', outer_request: 'outer-request-1' },
        { source_asset: 'tube2', target_asset: '5-well-B1', outer_request: 'outer-request-2' }
      ]
    end

    let(:child_plate) do
      create :plate_for_submission, purpose_name: child_purpose_name, barcode_number: '5', size: 96
    end

    let(:pooled_plates_attributes) do
      [
        {
          child_purpose_uuid: child_purpose_uuid,
          parent_uuids: [parent1_tube_uuid, parent2_tube_uuid],
          user_uuid: user_uuid
        }
      ]
    end

    context 'when the submission is created' do
      describe 'internal methods' do
        it 'determines the configuration for the submission' do
          expect(subject.send(:configured_params)).to eq(
            {
              'allowed_extra_barcodes' => false,
              'request_options' => {
                'fragment_size_required_from' => '200',
                'fragment_size_required_to' => '800',
                'library_type' => 'example_library'
              },
              'template_name' => 'example'
            }
          )
        end

        context 'if there is more than one configuration' do
          let!(:purpose_config) do
            create :multi_stamp_tubes_purpose_configs, name: child_purpose_name, uuid: child_purpose_uuid
          end

          it 'adds an error' do
            subject.send(:configured_params)
            expect(subject.errors.full_messages).to include('Expected only one submission')
          end
        end

        describe '#autodetect_studies' do
          it 'returns true when specified in the config' do
            expect(subject).to receive(:configured_params).and_return({ autodetect_studies: true, request_options: {} })
            expect(subject.send(:autodetect_studies)).to be(true)
          end

          it 'returns false when specified in the config' do
            expect(subject).to receive(:configured_params).and_return(
              { autodetect_studies: false, request_options: {} }
            )
            expect(subject.send(:autodetect_studies)).to be(false)
          end

          it 'returns false if not specified in the config' do
            expect(subject).to receive(:configured_params).and_return({ request_options: {} })
            expect(subject.send(:autodetect_studies)).to be(false)
          end
        end

        describe '#autodetect_projects' do
          it 'returns true when specified in the config' do
            expect(subject).to receive(:configured_params).and_return(
              { autodetect_projects: true, request_options: {} }
            )
            expect(subject.send(:autodetect_projects)).to be(true)
          end

          it 'returns false when specified in the config' do
            expect(subject).to receive(:configured_params).and_return(
              { autodetect_projects: false, request_options: {} }
            )
            expect(subject.send(:autodetect_projects)).to be(false)
          end

          it 'returns false if not specified in the config' do
            expect(subject).to receive(:configured_params).and_return({ request_options: {} })
            expect(subject.send(:autodetect_projects)).to be(false)
          end
        end
      end
    end

    describe '#save!' do
      before do
        expect(subject).to receive(:parent_tubes).and_return([parent1, parent2])
        expect(subject).to receive(:source_tube_outer_request_uuid).with(parent1).and_return('outer-request-1')
        expect(subject).to receive(:source_tube_outer_request_uuid).with(parent2).and_return('outer-request-2')
      end

      context 'when sources are from multiple studies' do
        before do
          expect('Sequencescape::Api::V2::Submission'.constantize).to receive(:where).and_return(
            [multiple_study_submission]
          )
        end

        # set up two tube to plate well transfers, each from a different study
        let(:aliquot1) { create :aliquot, study_id: 1 }
        let(:aliquot2) { create :aliquot, study_id: 2 }

        let(:parent1) do
          create :stock_tube,
                 uuid: parent1_tube_uuid,
                 purpose_uuid: 'parent-tube-purpose-uuid',
                 receptacle: parent1_receptacle,
                 aliquots: [aliquot1]
        end
        let(:parent2) do
          create :stock_tube,
                 uuid: parent2_tube_uuid,
                 purpose_uuid: 'parent-tube-purpose-uuid',
                 receptacle: parent2_receptacle,
                 aliquots: [aliquot2]
        end

        let(:orders_attributes) do
          [
            {
              attributes: {
                submission_template_uuid: example_template_uuid,
                submission_template_attributes: {
                  asset_uuids: parent_receptacle_uuids,
                  request_options: purpose_config[:submission_options]['Cardinal library prep']['request_options'],
                  user_uuid: user_uuid,
                  autodetect_studies: false,
                  autodetect_projects: false
                }
              },
              uuid_out: 'order-uuid'
            }
          ]
        end

        let(:submissions_attributes) do
          [
            {
              attributes: {
                and_submit: true,
                order_uuids: ['order-uuid'],
                user_uuid: user_uuid
              },
              uuid_out: 'sub-uuid'
            }
          ]
        end

        let!(:multiple_study_submission) do
          create(:submission, uuid: 'sub-uuid', orders: [{ uuid: 'order-uuid' }, { uuid: 'order-2-uuid' }])
        end

        it 'creates a plate!' do
          expect_order_creation
          expect_pooled_plate_creation
          expect_submission_creation
          expect_transfer_request_collection_creation

          subject.save!
        end
      end
    end
  end
end
