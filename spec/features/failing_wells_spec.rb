# frozen_string_literal: true
require 'rails_helper'

feature 'Failing wells', js: true do
  has_a_working_api

  let(:user_uuid)      { 'user-uuid' }
  let(:user)           { json :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode)  { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:plate_uuid)     { SecureRandom.uuid }
  let(:example_plate)  { json :plate, uuid: plate_uuid, state: 'passed' }

  let!(:state_change_request) do
    stub_api_post(
      'state_changes',
      payload: {
        'state_change' => {
          user: user_uuid,
          target: plate_uuid,
          contents: %w(A2 A3),
          target_state: 'failed',
          reason: 'Individual Well Failure',
          customer_accepts_responsibility: nil
        }
      },
      body: '{}' # We don't care about the response
    )
  end

  # Setup stubs
  background do
    # Set-up the plate config
    Settings.purposes['stock-plate-purpose-uuid'] = { presenter_class: 'Presenters::StandardPresenter', asset_type: 'Plate' }
    Settings.purposes['child-purpose-0'] = { presenter_class: 'Presenters::StandardPresenter', asset_type: 'Plate' }
    # We look up the user
    stub_search_and_single_result('Find user by swipecard code', { 'search' => { 'swipecard_code' => user_swipecard } }, user)
    # We lookup the plate
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => plate_barcode } }, example_plate)
    # We get the actual plate
    stub_api_get(plate_uuid, body: example_plate)
    stub_api_get(plate_uuid, 'wells', body: json(:well_collection, default_state: 'passed', custom_state: { 'B2' => 'failed' }))
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
    stub_api_get('stock-plate-purpose-uuid', body: json(:stock_plate_purpose))
    stub_api_get('stock-plate-purpose-uuid', 'children', body: json(:plate_purpose_collection, size: 1))
  end

  scenario 'failing wells' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    click_on('Fail Wells')

    within_fieldset('Select wells to fail') do
      # The actual check-boxes are invisible so we use the labels
      find(:label, text: 'A3').click
      find(:label, text: 'A2').click
      find(:label, text: 'B2').click
    end

    click_on('Fail selected wells')
    expect(find('#flashes')).to have_content('Selected wells have been failed')
    expect(state_change_request).to have_been_made
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
