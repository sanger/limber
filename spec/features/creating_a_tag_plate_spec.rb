# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Creating a tag plate', :js, :tag_plate do
  let(:user_uuid) { 'user-uuid' }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode) { parent_plate.barcode.machine }
  let(:child_purpose_uuid) { 'child-purpose-0' }
  let(:parent_plate) do
    create(
      :stock_plate,
      :has_pooling_metadata,
      pool_sizes: [8, 8],
      submission_pools: submission_pools,
      purpose_name: 'Limber Cherrypicked',
      purpose_uuid: 'stock-plate-purpose-uuid'
    )
  end
  let(:tag_plate_qcable_uuid) { 'tag-plate-qcable' }
  let(:tag_plate_uuid) { 'tag-plate-uuid' }
  let(:tag_template_uuid) { 'tag-layout-template-0' }

  let(:qcable_template) { create :tag_layout_template, uuid: tag_template_uuid }
  let(:qcable_lot) { create :lot, template: qcable_template }
  let(:qcable_labware) { create :plate, uuid: tag_plate_uuid }
  let(:qcable) { create :qcable, lot: qcable_lot, labware: qcable_labware, uuid: tag_plate_qcable_uuid }

  let(:tag_plate_barcode) { qcable_labware.labware_barcode.machine }
  let(:expected_transfers) { WellHelpers.stamp_hash(96) }
  let(:enforce_uniqueness) { true }

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

  let(:tag_layouts_attributes) do
    [
      {
        enforce_uniqueness: enforce_uniqueness,
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
          source_uuid: parent_plate.uuid,
          destination_uuid: tag_plate_uuid,
          transfer_template_uuid: 'custom-pooling',
          transfers: expected_transfers
        }
      }
    ]
  end

  let(:enforce_same_template_within_pool) { false }

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
    stub_plate(parent_plate)
    stub_plate(
      parent_plate,
      stub_search: false,
      custom_includes: 'wells.aliquots.request.poly_metadata'
    )
    stub_barcode_printers(create_list(:plate_barcode_printer, 3))
    stub_tag_layout_templates(templates)

    # API v2 requests for the qcable
    stub_qcable(qcable)
  end

  shared_examples 'it supports the plate' do
    let(:help_text) { "Click 'Create plate'" }

    before do
      expect_tag_layout_creation
      expect_transfer_creation

      stub_plate(create(:plate, uuid: tag_plate_uuid, purpose_uuid: 'stock-plate-purpose-uuid'))
      stub_post('StateChange')
      stub_qcable(qcable)
    end

    scenario 'creation with the plate' do
      expect_plate_conversion_creation

      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find_by_id('plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Tag Purpose plate')
      expect(page).to have_content('Tag plate addition')
      expect(find_by_id('tag-help')).to have_content(help_text)
      swipe_in('Tag plate barcode', with: tag_plate_barcode)
      expect(page).to have_content(qcable_lot.lot_number)
      expect(find_by_id('well_A2')).to have_content(a2_tag)
      click_on('Create Plate')
      expect(page).to have_content('New empty labware added to the system.')
    end
  end

  shared_examples 'it rejects the candidate plate' do
    before { stub_qcable(qcable) }

    scenario 'rejects the candidate plate' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find_by_id('plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Tag Purpose plate')
      expect(page).to have_content('Tag plate addition')
      swipe_in('Tag plate barcode', with: tag_plate_barcode)
      expect(page).to have_button('Create Plate', disabled: true)
      expect(page).to have_content(tag_error)
    end
  end

  shared_examples 'a recognised template' do
    context 'with a single indexed tag plate' do
      let(:template_factory) { :tag_layout_template }

      context 'when nothing has been done on a cross plate pool' do
        let(:submission_pools) { create_list(:dual_submission_pool, 1) }
        let(:tag_error) { 'Pool is spread across multiple plates. UDI plates must be used.' }

        it_behaves_like 'it rejects the candidate plate'
      end

      context 'when nothing has been done on a non cross plate pool' do
        # Fails on creation with the plate
        # with configured templates - and matching scanned template: expected to find text "2" in ""
        # with no configured templates: expected to find text "9" in ""
        let(:submission_pools) { create_list(:submission_pool, 1) }
        let(:enforce_uniqueness) { false }

        it_behaves_like 'it supports the plate'
      end

      context 'when the pool has been tagged by plates' do
        let(:submission_pools) do
          create_list(:dual_submission_pool, 1, used_template_uuids: ['tag-layout-template-1'])
        end
        let(:tag_error) { 'Pool is spread across multiple plates. UDI plates must be used.' }

        it_behaves_like 'it rejects the candidate plate'
      end
    end

    context 'with a dual indexed tag plate' do
      let(:template_factory) { :dual_index_tag_layout_template }

      context 'when nothing has been done' do
        let(:enforce_uniqueness) { false }
        let(:submission_pools) { create_list(:submission_pool, 1) }

        it_behaves_like 'it supports the plate'
      end

      context 'when the pool has been tagged by plates' do
        let(:submission_pools) do
          create_list(:dual_submission_pool, 1, used_template_uuids: ['tag-layout-template-1'])
        end

        it_behaves_like 'it supports the plate'
      end

      context 'when the template has been used' do
        let(:submission_pools) do
          create_list(:dual_submission_pool, 1, used_template_uuids: ['tag-layout-template-0'])
        end
        let(:tag_error) { 'This template has already been used.' }

        it_behaves_like 'it rejects the candidate plate'
      end

      context 'when all the plates in the pool must use the same template' do
        # This happens when they are derived from the same original samples, so shouldn't be de-plexed.
        # Like in the Heron 96 tailed pipeline.

        # set purposes config to enforce_same_template_within_pool
        let(:enforce_same_template_within_pool) { true }

        # Used for the expectations on tag layout creations above.
        let(:enforce_uniqueness) { false }

        # don't use dual_submission_pool_collection - we only want 1 source plate in our submission
        let(:submission_pools) { create_list(:submission_pool, 1, used_template_uuids: [used_template_uuid]) }

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
      let(:submission_pools) { create_list(:submission_pool, 1) }
      let(:template_factory) { :dual_index_tag_layout_template }
      let(:tag_template_uuid) { 'unrecognised template' }
      let(:tag_error) { 'It is not approved for use with this pipeline.' }

      it_behaves_like 'it rejects the candidate plate'
    end
  end
end
