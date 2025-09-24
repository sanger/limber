# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::TaggedPlate, :tag_plate do
  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from plates'

  let(:plate_uuid) { 'example-plate-uuid' }
  let(:plate_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:pools) { 0 }
  let(:plate) do
    create(
      :v2_plate,
      :has_pooling_metadata,
      uuid: plate_uuid,
      barcode_number: 2,
      pool_sizes: [8, 8],
      submission_pools_count: pools
    )
  end
  let(:transfer_template_uuid) { 'custom-pooling' }
  let(:expected_transfers) { WellHelpers.stamp_hash(96) }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let(:disable_cross_plate_pool_detection) { false }

  before do
    create(
      :purpose_config,
      name: child_purpose_name,
      uuid: child_purpose_uuid,
      disable_cross_plate_pool_detection: disable_cross_plate_pool_detection
    )
    stub_v2_plate(plate)
  end

  context 'on new' do
    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: plate_uuid } }

    it 'can be created' do
      expect(subject).to be_a described_class
    end

    it 'describes the parent barcode' do
      expect(subject.parent.barcode.ean13).to eq(plate_barcode)
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
      # Which is now unused. No method explicitly called `tag_plates_list` comes from
      # `delegate :used?, :list, :names, to: :tag_plates, prefix: true`
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

    context 'when a submission is split over multiple plates' do
      let(:pools) { 1 }

      context 'and nothing has been used' do
        it 'requires tag2' do
          expect(subject.requires_tag2?).to be true
        end
      end

      context 'and dual index plates have been used' do
        it 'requires tag2' do
          expect(subject.requires_tag2?).to be true
        end
      end

      context 'and detection has been disabled' do
        let(:disable_cross_plate_pool_detection) { true }

        it 'requires tag2' do
          expect(subject.requires_tag2?).to be false
        end
      end
    end

    context 'when a submission is not split over multiple plates' do
      it 'does not require tag2' do
        expect(subject.requires_tag2?).to be false
      end
    end

    context 'when a submission is not split over multiple plates but a plate has been recorded' do
      it 'does not require tag2' do
        expect(subject.requires_tag2?).to be false
      end
    end
  end

  context 'On create' do
    let(:tag_plate_barcode) { '1234567890' }
    let(:tag_plate_uuid) { 'tag-plate' }
    let(:tag_template_uuid) { 'tag-layout-template' }

    let(:plate_conversions_attributes) do
      [{ parent_uuid: plate_uuid, purpose_uuid: child_purpose_uuid, target_uuid: tag_plate_uuid, user_uuid: user_uuid }]
    end

    let(:state_changes_attributes) do
      [
        {
          reason: 'Used in Library creation',
          target_state: 'exhausted',
          target_uuid: tag_plate_uuid,
          user_uuid: user_uuid
        }
      ]
    end

    let(:tag_layouts_attributes) do
      [
        {
          enforce_uniqueness: false,
          plate_uuid: tag_plate_uuid,
          tag_layout_template_uuid: tag_template_uuid,
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
            destination_uuid: tag_plate_uuid,
            transfer_template_uuid: transfer_template_uuid,
            transfers: expected_transfers
          }
        }
      ]
    end

    context 'With a tag plate' do
      let(:form_attributes) do
        {
          purpose_uuid: child_purpose_uuid,
          parent_uuid: plate_uuid,
          user_uuid: user_uuid,
          tag_plate_barcode: tag_plate_barcode,
          tag_plate: {
            asset_uuid: tag_plate_uuid,
            template_uuid: tag_template_uuid
          }
        }
      end

      it_behaves_like 'it has a custom page', 'tagged_plate'

      it 'can be created' do
        expect(subject).to be_a described_class
      end

      context 'on save' do
        it 'creates a tag plate' do
          expect_plate_conversion_creation
          expect_state_change_creation
          expect_tag_layout_creation
          expect_transfer_creation

          expect(subject.save).to be true
        end

        it 'has the correct child (and uuid)' do
          expect_plate_conversion_creation # We need the return value and this expectation mocks it for us.
          stub_api_v2_post('StateChange')
          stub_api_v2_post('TagLayout')
          stub_api_v2_post('Transfer')

          expect(subject.save).to be true
          expect(subject.child.uuid).to eq(tag_plate_uuid)
        end
      end
    end
  end
end
