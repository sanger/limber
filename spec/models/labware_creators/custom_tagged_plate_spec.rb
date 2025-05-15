# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::CustomTaggedPlate, :tag_plate do
  subject { described_class.new(api, form_attributes) }

  it_behaves_like 'it only allows creation from plates'

  has_a_working_api

  let(:plate_uuid) { 'example-plate-uuid' }
  let(:plate_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:plate) { create(:v2_plate, :has_pooling_metadata, uuid: plate_uuid, barcode_number: 2, pool_sizes: [8, 8]) }
  let(:wells_in_column_order) { WellHelpers.column_order }
  let(:transfer_template_uuid) { 'custom-pooling' }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let(:child_plate) { create(:v2_plate, uuid: 'example-child-uuid') }

  before do
    create :purpose_config, uuid: child_purpose_uuid, name: child_purpose_name
    stub_v2_plate(plate)
    stub_api_v2_post('StateChange')
    stub_api_v2_post('PooledPlateCreation')
    stub_api_v2_post('TransferRequestCollection')
    stub_api_v2_post('TagLayout')
    allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(uuid: child_plate.uuid).and_return(child_plate)
  end

  context 'on new' do
    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: plate_uuid } }

    # These values all describe the returned json.
    # They are used to prevent magic numbers from appearing in the specs
    let(:plate_size) { 96 }
    let(:occupied_wells) { 30 }
    let(:pool_size) { 15 }
    let(:largest_tag_group) { 120 }

    let(:maximum_tag_offset) { largest_tag_group - occupied_wells }
    let(:maximum_well_offset) { plate_size - occupied_wells + 1 }

    it 'can be created' do
      expect(subject).to be_a described_class
    end

    it 'describes the parent uuid' do
      expect(subject.parent_uuid).to eq(plate_uuid)
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_purpose_uuid)
    end

    context 'fetching layout templates' do
      let(:layout_hash) do
        WellHelpers.column_order.each_with_index.map do |w, i|
          pool = i < 8 ? 1 : 2
          [w, [pool, i + 1]]
        end
      end

      let(:tag_layout_templates) { create_list :v2_tag_layout_template, 2 }

      before { stub_v2_tag_layout_templates(tag_layout_templates) }

      # Recording existing behaviour here before refactoring, but this looks like it might be just for pool tagging.
      # Which is now unused.
      it 'lists tag groups' do
        expect(subject.tag_plates_list).to eq(
          tag_layout_templates[0].uuid => {
            tags: layout_hash,
            used: false,
            dual_index: false,
            approved: true,
            matches_templates_in_pool: true
          },
          tag_layout_templates[1].uuid => {
            tags: layout_hash,
            used: false,
            dual_index: false,
            approved: true,
            matches_templates_in_pool: true
          }
        )
      end
    end
  end

  context 'On create' do
    let(:tag_plate_uuid) { 'tag-plate' }
    let(:tag_template_uuid) { 'tag-layout-template' }
    let(:parents) { [plate_uuid, tag_plate_uuid] }

    let(:child_plate) { create :v2_plate }

    let(:pooled_plates_attributes) do
      [{ child_purpose_uuid: child_purpose_uuid, parent_uuids: parents, user_uuid: user_uuid }]
    end

    let(:state_changes_attributes) do
      [
        {
          reason: 'Used in Library creation',
          target_uuid: tag_plate_uuid,
          target_state: 'exhausted',
          user_uuid: user_uuid
        }
      ]
    end

    let(:transfers_attributes) do
      [
        {
          arguments: {
            user_uuid: user_uuid,
            source_uuid: plate_uuid,
            destination_uuid: child_plate.uuid,
            transfer_template_uuid: transfer_template_uuid,
            transfers: WellHelpers.stamp_hash(96)
          }
        }
      ]
    end

    def expect_tag_layout_creation
      expect_api_v2_posts(
        'TagLayout',
        [
          {
            user_uuid: user_uuid,
            plate_uuid: child_plate.uuid,
            tag_group_uuid: 'tag-group-uuid',
            tag2_group_uuid: 'tag2-group-uuid',
            direction: 'column',
            walking_by: 'manual by plate',
            initial_tag: '1',
            tags_per_well: 1
          }
        ]
      )
    end

    def expect_transfer_request_collection_creation
      expect_api_v2_posts(
        'TransferRequestCollection',
        [
          hash_including(
            transfer_requests_attributes:
              array_including(hash_including(source_asset: anything, outer_request: anything, target_asset: anything)),
            user_uuid: user_uuid
          )
        ]
      )
    end
    context 'Providing simple options' do
      let(:tag_plate_state) { 'available' }

      let(:form_attributes) do
        {
          purpose_uuid: child_purpose_uuid,
          parent_uuid: plate_uuid,
          user_uuid: user_uuid,
          tag_plate: {
            asset_uuid: tag_plate_uuid,
            template_uuid: tag_template_uuid,
            state: tag_plate_state
          },
          tag_layout: {
            user_uuid: 'user-uuid',
            tag_group_uuid: 'tag-group-uuid',
            tag2_group_uuid: 'tag2-group-uuid',
            direction: 'column',
            walking_by: 'manual by plate',
            initial_tag: '1',
            substitutions: {
            },
            tags_per_well: 1
          }
        }
      end

      let(:parent_plate) { create(:v2_plate, uuid: plate_uuid) }
      let(:child_plate) { create(:v2_plate, uuid: 'bcad7d16-1592-420c-9052-71e345b4fad0') }

      it 'can be created' do
        expect(subject).to be_a described_class
      end

      it_behaves_like 'it has a custom page', 'custom_tagged_plate'

      context 'on save' do
        context 'with an available tag plate' do
          let(:tag_plate_state) { 'available' }

          it 'creates a tag plate' do
            expect_pooled_plate_creation
            expect_state_change_creation
            expect_tag_layout_creation
            expect_transfer_request_collection_creation
            expect(subject.save).to be true
          end

          it 'has the correct child (and uuid)' do
            stub_v2_pooled_plate_creation
            stub_api_v2_post('TagLayout')
            stub_api_v2_post('TransferRequestCollection')
            stub_api_v2_post('StateChange')

            expect(subject.save).to be true

            # This will be our new plate
            expect(subject.child.uuid).to eq(child_plate.uuid)
          end

          context 'when a user has exhausted the plate in another tab' do
            it 'creates a tag plate' do
              expect_pooled_plate_creation
              expect_state_change_creation
              expect_tag_layout_creation
              expect_transfer_request_collection_creation

              expect(subject.save).to be true
            end
          end
        end

        context 'with an exhausted tag plate' do
          let(:tag_plate_state) { 'exhausted' }

          it 'creates a tagged plate' do
            # This one will be VERY different
            expect_tag_layout_creation

            expect_pooled_plate_creation
            expect_transfer_request_collection_creation
            expect(Sequencescape::Api::V2::StateChange).not_to receive(:create!)

            expect(subject.save).to be true
          end

          it 'has the correct child (and uuid)' do
            stub_v2_pooled_plate_creation
            stub_api_v2_post('TagLayout')
            stub_api_v2_post('TransferRequestCollection')

            expect(subject.save).to be true

            # This will be our new plate
            expect(subject.child.uuid).to eq(child_plate.uuid)
          end
        end

        context 'without a tag plate' do
          let(:tag_plate_state) { '' }
          let(:tag_plate_uuid) { '' }
          let(:parents) { [plate_uuid] }

          it 'creates a tag plate' do
            expect_pooled_plate_creation
            expect_tag_layout_creation
            expect_transfer_request_collection_creation
            expect(Sequencescape::Api::V2::StateChange).not_to receive(:create!)

            expect(subject.save).to be true
          end

          it 'has the correct child (and uuid)' do
            stub_v2_pooled_plate_creation
            stub_api_v2_post('TagLayout')
            stub_api_v2_post('TransferRequestCollection')

            expect(subject.save).to be true
            expect(subject.child.uuid).to eq(child_plate.uuid)
          end
        end
      end
    end
  end
end
