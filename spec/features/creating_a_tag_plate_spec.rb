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
  let(:example_plate)         { json :stock_plate, uuid: plate_uuid, state: 'passed', pool_sizes: [8, 8] }
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

  include_context 'a tag plate creator'
  include_context 'a tag plate creator with dual indexing'

  # Setup stubs
  background do
    Forms::CreationForm.default_transfer_template_uuid = 'transfer-template-uuid'
    # Set-up the plate config
    Settings.purposes = {}
    Settings.purposes['stock-plate-purpose-uuid'] = { presenter_class: 'Presenters::StandardPresenter', asset_type: 'Plate' }
    Settings.purposes['child-purpose-0'] = { presenter_class: 'Presenters::StandardPresenter', form_class: 'Forms::TaggingForm', asset_type: 'Plate', name: 'Tag Purpose', parents: ['Limber Cherrypicked'] }
    # We look up the user
    stub_search_and_single_result('Find user by swipecard code', { 'search' => { 'swipecard_code' => user_swipecard } }, user)
    # We lookup the plate
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => plate_barcode } }, example_plate)
    # We get the actual plate
    stub_api_get(plate_uuid, body: example_plate)
    stub_api_get(plate_uuid, 'wells', body: json(:well_collection))
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
    stub_api_get('stock-plate-purpose-uuid', body: json(:stock_plate_purpose))
    stub_api_get('stock-plate-purpose-uuid', 'children', body: json(:plate_purpose_collection, size: 1))
    stub_api_get('tag_layout_templates', body: json(:tag_layout_template_collection, size: 2))
    stub_api_get('tag2_layout_templates', body: json(:tag2_layout_template_collection, size: 2))
    stub_api_get(plate_uuid, 'submission_pools', body: json(:dual_submission_pool_collection))

    stub_api_get(tag_plate_qcable_uuid, body: tag_plate_qcable)
    stub_api_get('lot-uuid', body: json(:tag_lot, lot_number: '12345', template_uuid: tag_template_uuid))
    stub_api_get('tag-lot-type-uuid', body: json(:tag_lot_type))
    stub_api_get(tag2_tube_qcable_uuid, body: tag2_tube_qcable)
    stub_api_get('lot2-uuid', body: json(:tag2_lot, lot_number: '67890', template_uuid: tag2_template_uuid))
    stub_api_get('tag2-lot-type-uuid', body: json(:tag2_lot_type))

    stub_api_get(tag_plate_uuid, body: json(:plate, uuid: tag_plate_uuid))
    stub_api_get(tag_plate_uuid, 'wells', body: json(:well_collection))
  end

  scenario 'of a recognised type' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    plate_title = find('#plate-title')
    expect(plate_title).to have_text('Limber Cherrypicked')
    click_on('Add an empty Tag Purpose plate')
    expect(page).to have_content('Tag plate addition')
    expect(page).to have_content('Tag plate addition')
    stub_search_and_single_result('Find qcable by barcode', { 'search' => { 'barcode' => tag_plate_barcode } }, tag_plate_qcable)
    fill_in('Tag plate barcode', with: tag_plate_barcode)
    expect(page).to have_content('12345')
    stub_search_and_single_result('Find qcable by barcode', { 'search' => { 'barcode' => tag2_tube_barcode } }, tag2_tube_qcable)
    fill_in('Tag2 tube barcode', with: tag2_tube_barcode)
    expect(page).to have_content('67890')
    click_on('Create Plate')
    expect(page).to have_content('New empty labware added to the system.')
  end

  def fill_in_swipecard_and_barcode(swipecard, barcode)
    visit root_path

    within '.content-main' do
      fill_in 'User Swipecard', with: swipecard
      find_field('User Swipecard').send_keys :enter
      expect(page).to have_content('Jane Doe')
      fill_in 'Plate or Tube Barcode', with: barcode
      find_field('Plate or Tube Barcode').send_keys :enter
    end
  end
end
