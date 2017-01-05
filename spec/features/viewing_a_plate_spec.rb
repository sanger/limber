# frozen_string_literal: true
require 'rails_helper'
require 'pry'

feature 'Viewing a plate', js: true do
  has_a_working_api(times: 5)

  let(:user)           { json :user }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode)  { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:plate_uuid)     { SecureRandom.uuid }
  let(:example_plate)  { json :stock_plate, uuid: plate_uuid }

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
    stub_request(:get, 'http://example.com:3000/' + plate_uuid)
      .to_return(status: 200, body: example_plate, headers: { 'content-type' => 'application/json' })

    stub_request(:get, 'http://example.com:3000/' + plate_uuid + '/wells')
      .to_return(status: 200, body: json(:well_collection), headers: { 'content-type' => 'application/json' })

    stub_request(:get, 'http://example.com:3000/barcode_printers')
      .to_return(status: 200, body: json(:barcode_printer_collection), headers: { 'content-type' => 'application/json' })

    stub_request(:get, 'http://example.com:3000/stock-plate-purpose-uuid')
      .to_return(status: 200, body: json(:stock_plate_purpose), headers: { 'content-type' => 'application/json' })

    stub_request(:get, 'http://example.com:3000/stock-plate-purpose-uuid/children')
      .to_return(status: 200, body: json(:plate_purpose_collection, size: 1), headers: { 'content-type' => 'application/json' })
  end

  scenario 'of a recognised type' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    expect(page).to have_content('Limber Cherrypicked')
  end

  def fill_in_swipecard_and_barcode(swipecard, barcode)
    visit root_path

    within '.content-main' do
      fill_in 'User Swipecard', with: swipecard
      find_field('User Swipecard').send_keys :enter
      fill_in 'Plate or Tube Barcode', with: barcode
      find_field('Plate or Tube Barcode').send_keys :enter
    end
  end
end
