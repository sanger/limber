# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/shared_tagging_examples'

feature 'Creating a tag plate', js: true do
  has_a_working_api
  let(:user_uuid)             { 'user-uuid' }
  let(:user)                  { json :user, uuid: user_uuid }
  let(:user_swipecard)        { 'abcdef' }
  let(:plate_barcode)         { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:plate_uuid)            { SecureRandom.uuid }
  let(:child_purpose_uuid)    { 'child-purpose-0' }
  let(:pools) { 1 }
  let(:example_plate)         { json :stock_plate, uuid: plate_uuid, state: 'passed', pool_sizes: [8, 8], submission_pools_count: pools }
  let(:tag_plate_barcode)     { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:tag_plate_qcable_uuid) { 'tag-plate-qcable' }
  let(:tag_plate_uuid)        { 'tag-plate-uuid' }
  let(:tag2_tube_uuid)        { 'tag-tube-uuid' }
  let(:tag_plate_qcable)      { json :tag_plate_qcable, uuid: tag_plate_qcable_uuid, lot_uuid: 'lot-uuid' }
  let(:tag2_tube_qcable_uuid) { 'tag-tube-qcable' }
  let(:tag2_tube_barcode)     { SBCF::SangerBarcode.new(prefix: 'NT', number: 1).machine_barcode.to_s }
  let(:tag2_tube_qcable)      { json :tag2_tube_qcable, uuid: tag2_tube_qcable_uuid, lot_uuid: 'lot2-uuid' }
  let(:transfer_template_uuid) { 'transfer-template-uuid' }
  let(:transfer_template) { json :transfer_template, uuid: transfer_template_uuid }
  let(:tag_template_uuid) { 'tag-layout-template-0' }
  let(:tag2_template_uuid) { 'tag2-layout-template-0' }

  let(:submission_pools) { json(:submission_pool_collection) }
  let(:help_text) { 'This plate does not appear to be part of a larger pool. Dual indexing is optional.' }

  let(:tag_lot_number) { 'tag_lot_number' }
  let(:tag2_lot_number) { 'tag2_lot_number' }

  include_context 'a tag plate creator'
  include_context 'a tag plate creator with dual indexing'

  # Setup stubs
  background do
    LabwareCreators::Base.default_transfer_template_uuid = 'transfer-template-uuid'
    # Set-up the plate config
    Settings.purposes = {}
    Settings.purposes['stock-plate-purpose-uuid'] = build :purpose_config # { presenter_class: 'Presenters::StandardPresenter', asset_type: 'plate' }
    Settings.purposes['child-purpose-0'] = build :purpose_config, form_class: 'LabwareCreators::TaggedPlate',
                                                                  name: 'Tag Purpose',
                                                                  parents: ['Limber Cherrypicked'],
                                                                  tag_layout_templates: acceptable_templates
    # We look up the user
    stub_search_and_single_result('Find user by swipecard code', { 'search' => { 'swipecard_code' => user_swipecard } }, user)
    # We lookup the plate
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => plate_barcode } }, example_plate)
    # We get the actual plate
    stub_api_get(plate_uuid, body: example_plate)
    stub_api_get(plate_uuid, 'wells', body: json(:well_collection))
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
    stub_api_get('tag_layout_templates', body: templates)
    stub_api_get('tag2_layout_templates', body: json(:tag2_layout_template_collection, size: 2))
    stub_api_get(plate_uuid, 'submission_pools', body: submission_pools)

    stub_api_get(tag_plate_qcable_uuid, body: tag_plate_qcable)
    stub_api_get('lot-uuid', body: json(:tag_lot, lot_number: tag_lot_number, template_uuid: tag_template_uuid))
    stub_api_get('tag-lot-type-uuid', body: json(:tag_lot_type))
    stub_api_get(tag2_tube_qcable_uuid, body: tag2_tube_qcable)
    stub_api_get('lot2-uuid', body: json(:tag2_lot, lot_number: tag2_lot_number, template_uuid: tag2_template_uuid))
    stub_api_get('tag2-lot-type-uuid', body: json(:tag2_lot_type))

    stub_api_get(tag_plate_uuid, body: json(:plate, uuid: tag_plate_uuid, purpose_uuid: 'stock-plate-purpose-uuid'))
    stub_api_get(tag_plate_uuid, 'wells', body: json(:well_collection))
  end

  shared_examples 'supports dual-index plates' do
    let(:help_text) { "Click 'Create plate'" }

    scenario 'creation with dual-index plates' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find('#plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Tag Purpose plate')
      expect(page).to have_content('Tag plate addition')
      expect(find('#tag-help')).to have_content(help_text)
      stub_search_and_single_result('Find qcable by barcode', { 'search' => { 'barcode' => tag_plate_barcode } }, tag_plate_qcable)
      fill_in('Tag plate barcode', with: tag_plate_barcode)
      expect(page).to have_content(tag_lot_number)
      expect(find('#well_A2')).to have_content(a2_tag)
      click_on('Create Plate')
      expect(page).to have_content('New empty labware added to the system.')
    end
  end

  shared_examples 'supports a plate-tube combo' do
    scenario 'allows plate creation' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find('#plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Tag Purpose plate')
      expect(page).to have_content('Tag plate addition')
      stub_search_and_single_result('Find qcable by barcode', { 'search' => { 'barcode' => tag_plate_barcode } }, tag_plate_qcable)
      fill_in('Tag plate barcode', with: tag_plate_barcode)
      expect(page).to have_content(tag_lot_number)
      stub_search_and_single_result('Find qcable by barcode', { 'search' => { 'barcode' => tag2_tube_barcode } }, tag2_tube_qcable)
      fill_in('Tag2 tube barcode', with: tag2_tube_barcode)
      expect(page).to have_content(tag2_lot_number)
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
      stub_search_and_single_result('Find qcable by barcode', { 'search' => { 'barcode' => tag_plate_barcode } }, tag_plate_qcable)
      fill_in('Tag plate barcode', with: tag_plate_barcode)
      # expect(page).to have_content('The Tag Plate is not suitable.')
      expect(page).to have_button('Create Plate', disabled: true)
      expect(page).to have_content(tag_error)
    end
  end

  shared_examples 'a recognised template' do
    context 'a single indexed tag plate' do
      let(:template_factory) { :tag_layout_template }

      context 'when nothing has been done' do
        let(:submission_pools) { json(:dual_submission_pool_collection) }
        let(:help_text) { 'This plate is part of a larger pool and must be dual indexed.' }
        it_behaves_like 'supports a plate-tube combo'
      end
      context 'when a tube has already been used in the pool' do
        let(:submission_pools) do
          json(:dual_submission_pool_collection,
               used_tag2_templates: [{ uuid: 'tag2-layout-template-1', name: 'Used template' }],
               used_tag_templates: [{ uuid: 'tag-layout-template-0', name: 'Used template' }]) # The same template has been used, but we don't actually care here
        end
        let(:help_text) { 'This plate is part of a larger pool which has been indexed with tubes.' }
        it_behaves_like 'supports a plate-tube combo'
      end
      context 'when the pool has been tagged by plates' do
        let(:submission_pools) { json(:dual_submission_pool_collection, used_tag_templates: [{ uuid: 'tag-layout-template-1', name: 'Used template' }]) }
        let(:help_text) { 'This plate is part of a larger pool which has been indexed with UDI plates.' }
        let(:tag_error) { 'Pool has been tagged with a UDI plate. UDI plates must be used.' }
        it_behaves_like 'it rejects the candidate plate'
      end
    end

    context 'a dual indexed tag plate' do
      let(:template_factory) { :dual_index_tag_layout_template }

      context 'when nothing has been done' do
        let(:submission_pools) { json(:dual_submission_pool_collection) }
        let(:help_text) { 'This plate is part of a larger pool and must be dual indexed.' }
        it_behaves_like 'supports dual-index plates'
      end
      context 'when the pool has been tagged by plates' do
        let(:submission_pools) { json(:dual_submission_pool_collection, used_tag_templates: [{ uuid: 'tag-layout-template-1', name: 'Used template' }]) }
        let(:help_text) { 'This plate is part of a larger pool which has been indexed with UDI plates.' }
        it_behaves_like 'supports dual-index plates'
      end
      context 'when the template has been used' do
        let(:submission_pools) { json(:dual_submission_pool_collection, used_tag_templates: [{ uuid: 'tag-layout-template-0', name: 'Used template' }]) }
        let(:help_text) { 'This plate is part of a larger pool which has been indexed with UDI plates.' }
        let(:tag_error) { 'This template has already been used.' }
        it_behaves_like 'it rejects the candidate plate'
      end
      context 'when a tube has already been used in the pool' do
        let(:submission_pools) { json(:dual_submission_pool_collection, used_tag2_templates: [{ uuid: 'tag2-layout-template-1', name: 'Used template' }]) }
        let(:help_text) { 'This plate is part of a larger pool which has been indexed with tubes.' }
        let(:tag_error) { 'Pool has been tagged with tube. Dual indexed plates are unsupported.' }
        it_behaves_like 'it rejects the candidate plate'
      end
    end
  end

  feature 'with no configure templates' do
    let(:acceptable_templates) { nil }
    let(:templates) { json(:tag_layout_template_collection, size: 2, direction: direction, template_factory: template_factory) }
    let(:tag_layout_template) { json(template_factory, uuid: tag_template_uuid) }

    feature 'by column layout' do
      let(:direction) { 'column' }
      let(:a2_tag)    { '9' }
      it_behaves_like 'a recognised template'
    end

    feature 'by row layout' do
      let(:direction) { 'row' }
      let(:a2_tag)    { '2' }
      it_behaves_like 'a recognised template'
    end
  end

  feature 'with configured templates' do
    let(:acceptable_templates) { ['Tag2 layout 0'] }
    let(:direction) { 'row' }
    let(:templates) { json(:tag_layout_template_collection, size: 2, direction: direction, template_factory: template_factory) }
    let(:a2_tag)    { '2' }

    feature 'and matching scanned template' do
      it_behaves_like 'a recognised template'
    end

    feature 'and non matching scanned template' do
      let(:template_factory) { :dual_index_tag_layout_template }
      let(:tag_template_uuid) { 'unrecognised template' }
      let(:tag_error) { 'It does not contain suitable tags.' }
      it_behaves_like 'it rejects the candidate plate'
    end
  end
end
