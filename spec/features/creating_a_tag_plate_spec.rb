# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/shared_tagging_examples'

RSpec.feature 'Creating a tag plate', js: true, tag_plate: true do
  has_a_working_api

  let(:user_uuid) { 'user-uuid' }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode) { parent_plate.barcode.machine }
  let(:child_purpose_uuid) { 'child-purpose-0' }
  let(:parent_plate) do
    create(
      :v2_stock_plate,
      :has_pooling_metadata,
      pool_sizes: [8, 8],
      submission_pools: submission_pools,
      purpose_name: 'Limber Cherrypicked',
      purpose_uuid: 'stock-plate-purpose-uuid'
    )
  end

  let(:tag_plate_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:tag_plate_qcable_uuid) { 'tag-plate-qcable' }
  let(:tag_plate_uuid) { 'tag-plate-uuid' }
  let(:tag_plate_qcable) { json :tag_plate_qcable, uuid: tag_plate_qcable_uuid, lot_uuid: 'lot-uuid' }
  let(:transfer_template_uuid) { 'custom-pooling' }
  let(:expected_transfers) { WellHelpers.stamp_hash(96) }
  let(:transfers_attributes) do
    [
      {
        arguments: {
          user_uuid: user_uuid,
          source_uuid: parent_plate.uuid,
          destination_uuid: tag_plate_uuid,
          transfer_template_uuid: transfer_template_uuid,
          transfers: expected_transfers
        }
      }
    ]
  end

  let(:plate_conversions_attributes) do
    [
      {
        parent_uuid: parent_plate.uuid,
        purpose_uuid: child_purpose_uuid,
        target_uuid: tag_plate_uuid,
        user_uuid: user_uuid
      }
    ]
  end

  let(:tag_template_uuid) { 'tag-layout-template-0' }

  let(:help_text) { 'This plate does not appear to be part of a larger pool. Dual indexing is optional.' }

  let(:tag_lot_number) { 'tag_lot_number' }
  let(:enforce_same_template_within_pool) { false }

  include_context 'a tag plate creator'

  # Setup stubs
  background do
    # Set-up the plate config
    create :purpose_config, uuid: 'stock-plate-purpose-uuid', name: 'Limber Cherrypicked'
    create(
      :tagged_purpose_config,
      tag_layout_templates: acceptable_templates,
      uuid: child_purpose_uuid,
      enforce_same_template_within_pool: enforce_same_template_within_pool
    )
    create :pipeline, relationships: { 'Limber Cherrypicked' => 'Tag Purpose' }

    # We look up the user
    stub_swipecard_search(user_swipecard, user)

    # We get the objects we need from the API stubs
    stub_v2_plate(parent_plate)
    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))
    stub_v2_tag_layout_templates(templates)

    # TODO: {Y24-190} Get rid of these v1 stubs after tag_layout_templates are moved to v2 in tagged_plate.rb
    stub_api_get(tag_template_uuid, body: json(:tag_layout_template, uuid: tag_template_uuid))
    stub_api_post(tag_template_uuid, body: json(:tag_layout_template, uuid: tag_template_uuid))

    # API v1 UUID requests for a qcable via qcable_presenter.
    stub_api_get(tag_plate_qcable_uuid, body: tag_plate_qcable)
    stub_api_get('lot-uuid', body: json(:tag_lot, lot_number: tag_lot_number, template_uuid: tag_template_uuid))
    stub_api_get('tag-lot-type-uuid', body: json(:tag_lot_type))
  end

  shared_examples 'it supports the plate' do
    let(:help_text) { "Click 'Create plate'" }

    before do
      expect_transfer_creation

      stub_v2_plate(create(:v2_plate, uuid: tag_plate_uuid, purpose_uuid: 'stock-plate-purpose-uuid'))
      stub_api_v2_post('StateChange')
    end

    scenario 'creation with the plate' do
      expect_plate_conversion_creation

      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find('#plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Tag Purpose plate')
      expect(page).to have_content('Tag plate addition')
      expect(find('#tag-help')).to have_content(help_text)
      stub_search_and_single_result(
        'Find qcable by barcode',
        { 'search' => { 'barcode' => tag_plate_barcode } },
        tag_plate_qcable
      )
      swipe_in('Tag plate barcode', with: tag_plate_barcode)
      expect(page).to have_content(tag_lot_number)
      expect(find('#well_A2')).to have_content(a2_tag)
      click_on('Create Plate')
      expect(page).to have_content('New empty labware added to the system.')
    end
  end

  shared_examples 'it rejects the candidate plate' do
    scenario 'rejects the candidate plate' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find('#plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Tag Purpose plate')
      expect(page).to have_content('Tag plate addition')
      stub_search_and_single_result(
        'Find qcable by barcode',
        { 'search' => { 'barcode' => tag_plate_barcode } },
        tag_plate_qcable
      )
      swipe_in('Tag plate barcode', with: tag_plate_barcode)
      expect(page).to have_button('Create Plate', disabled: true)
      expect(page).to have_content(tag_error)
    end
  end

  shared_examples 'a recognised template' do
    context 'with a single indexed tag plate' do
      let(:template_factory) { :v2_tag_layout_template }

      context 'when nothing has been done on a cross plate pool' do
        let(:submission_pools) { create_list(:v2_dual_submission_pool, 1) }
        let(:help_text) { 'This plate is part of a larger pool and must be indexed with UDI plates.' }
        let(:tag_error) { 'Pool is spread across multiple plates. UDI plates must be used.' }
        it_behaves_like 'it rejects the candidate plate'
      end

      context 'when nothing has been done on a non cross plate pool' do
        # Fails on creation with the plate
        # with configured templates - and matching scanned template: expected to find text "2" in ""
        # with no configured templates: expected to find text "9" in ""
        let(:submission_pools) { create_list(:v2_submission_pool, 1) }
        let(:help_text) { 'This plate does not appear to be part of a larger pool. Dual indexing is optional.' }
        let(:enforce_uniqueness) { false }
        it_behaves_like 'it supports the plate'
      end

      context 'when the pool has been tagged by plates' do
        let(:submission_pools) do
          create_list(:v2_dual_submission_pool, 1, used_template_uuids: ['tag-layout-template-1'])
        end
        let(:help_text) { 'This plate is part of a larger pool which has been indexed with UDI plates.' }
        let(:tag_error) { 'Pool is spread across multiple plates. UDI plates must be used.' }
        it_behaves_like 'it rejects the candidate plate'
      end
    end

    context 'with a dual indexed tag plate' do
      let(:template_factory) { :v2_dual_index_tag_layout_template }

      context 'when nothing has been done' do
        #let(:submission_pools) { json(:dual_submission_pool_collection) }
        let(:submission_pools) { create_list(:v2_submission_pool, 1) }
        let(:help_text) { 'This plate is part of a larger pool and must be indexed with UDI plates.' }
        it_behaves_like 'it supports the plate'
      end

      context 'when the pool has been tagged by plates' do
        let(:submission_pools) do
          create_list(:v2_dual_submission_pool, 1, used_template_uuids: ['tag-layout-template-1'])
        end
        let(:help_text) { 'This plate is part of a larger pool which has been indexed with UDI plates.' }
        it_behaves_like 'it supports the plate'
      end

      context 'when the template has been used' do
        let(:submission_pools) do
          create_list(:v2_dual_submission_pool, 1, used_template_uuids: ['tag-layout-template-0'])
        end
        let(:help_text) { 'This plate is part of a larger pool which has been indexed with UDI plates.' }
        let(:tag_error) { 'This template has already been used.' }
        it_behaves_like 'it rejects the candidate plate'
      end

      context 'when all the plates in the pool must use the same template' do
        # This happens when they are derived from the same original samples, so shouldn't be de-plexed.
        # Like in the Heron 96 tailed pipeline.

        # set purposes config to enforce_same_template_within_pool
        let(:enforce_same_template_within_pool) { true }

        # this is used in shared_tagging_examples when stubbing the tag_layout_creation_request
        let(:enforce_uniqueness) { false }

        # don't use dual_submission_pool_collection - we only want 1 source plate in our submission
        let(:submission_pools) { create_list(:v2_submission_pool, 1, used_template_uuids: [used_template_uuid]) }

        context 'when the template has been used' do
          # Fails on creation with the plate
          # with configured templates - and matching scanned template: expected to find text "2" in ""
          # with no configured templates: expected to find text "9" in ""
          let(:used_template_uuid) { 'tag-layout-template-0' }
          it_behaves_like 'it supports the plate'
        end

        context 'when the pool has been tagged by plates' do
          let(:used_template_uuid) { 'tag-layout-template-1' }
          let(:tag_error) { 'It doesn\'t match those already used for other plates in this submission pool.' }
          it_behaves_like 'it rejects the candidate plate'
        end
      end
    end
  end

  feature 'with no configured templates' do
    let(:acceptable_templates) { nil }
    let(:direction) { 'column' }

    let(:templates) do
      create_list(template_factory, 2, direction:) do |template, i|
        template.uuid = "tag-layout-template-#{i}"
        template.name = "Tag2 layout #{i}"
      end
    end
    let(:a2_tag) { '9' }

    it_behaves_like 'a recognised template'
  end

  feature 'with configured templates' do
    let(:acceptable_templates) { ['Tag2 layout 0'] }
    let(:direction) { 'row' }

    let(:templates) do
      create_list(template_factory, 2, direction:) do |template, i|
        template.uuid = "tag-layout-template-#{i}"
        template.name = "Tag2 layout #{i}"
      end
    end
    let(:a2_tag) { '2' }

    feature 'and matching scanned template' do
      it_behaves_like 'a recognised template'
    end

    feature 'and non matching scanned template' do
      let(:submission_pools) { create_list(:v2_submission_pool, 1) }
      let(:template_factory) { :v2_dual_index_tag_layout_template }
      let(:tag_template_uuid) { 'unrecognised template' }
      let(:tag_error) { 'It is not approved for use with this pipeline.' }
      it_behaves_like 'it rejects the candidate plate'
    end
  end
end
