# frozen_string_literal: true

require 'rails_helper'

feature 'Viewing a plate', js: true do
  has_a_working_api

  let(:user)           { json :user }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode)  { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:plate_uuid)     { SecureRandom.uuid }
  let(:example_plate)  { json :stock_plate, uuid: plate_uuid }
  let(:example_passed_plate)  { json :stock_plate, uuid: plate_uuid, state: 'passed' }
  let(:example_started_plate) { json :stock_plate, uuid: plate_uuid, state: 'started' }
  let(:wells_collection) { json(:well_collection) }

  # Setup stubs
  background do
    # Set-up the plate config
    Settings.purposes['stock-plate-purpose-uuid'] = { presenter_class: 'Presenters::StandardPresenter', asset_type: 'plate' }
    Settings.purposes['child-purpose-0'] = { presenter_class: 'Presenters::StandardPresenter', asset_type: 'plate', name: 'Child Purpose 0', parents: ['Limber Cherrypicked'] }
    # We look up the user
    stub_search_and_single_result('Find user by swipecard code', { 'search' => { 'swipecard_code' => user_swipecard } }, user)
    # We lookup the plate
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => plate_barcode } }, example_plate)
    # We get the actual plate
    stub_api_get(plate_uuid, body: example_plate)
    stub_api_get(plate_uuid, 'wells', body: wells_collection)
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
  end

  scenario 'of a recognised type' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    expect(find('#plate-show-page')).to have_content('Limber Cherrypicked')
    expect(find('.badge')).to have_content('pending')
  end

  scenario 'if a plate is passed creation of a child is allowed' do
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => plate_barcode } }, example_passed_plate)
    stub_api_get(plate_uuid, body: example_passed_plate)
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    expect(find('#plate-show-page')).to have_content('Limber Cherrypicked')
    expect(find('.badge')).to have_content('passed')
    expect(page).to have_button('Add an empty Child Purpose 0 plate')
  end

  scenario 'if a plate is started creation of a child is not allowed' do
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => plate_barcode } }, example_started_plate)
    stub_api_get(plate_uuid, body: example_started_plate)
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    expect(find('#plate-show-page')).to have_content('Limber Cherrypicked')
    expect(find('.badge')).to have_content('started')
    expect(page).not_to have_button('Add an empty Limber Example Purpose plate')
  end

  feature 'with a suboptimal well' do
    let(:wells_collection) { json(:well_collection, aliquot_factory: :suboptimal_aliquot) }
    scenario 'there is a warning' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('.asset-warnings')).to have_content('Wells contain suboptimal aliquots')
    end
    scenario 'the well is flagged as suboptimal' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(page).to have_css('#aliquot_A1.suboptimal')
    end
  end

  feature 'without a suboptimal well' do
    scenario 'there is a warning' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('#plate-show-page')).not_to have_content('Wells contain suboptimal aliquots')
    end
    scenario 'the well is flagged as suboptimal' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('#plate-show-page')).not_to have_css('#aliquot_A1.suboptimal')
    end
  end

  feature 'with transfers to tubes' do
    let(:example_plate) { json :plate, uuid: plate_uuid, transfers_to_tubes_count: 1, purpose_uuid: 'child-purpose-0' }

    before do
      stub_api_get(plate_uuid, 'transfers_to_tubes', body: json(:transfer_collection))
    end

    scenario 'we see the tube label form' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(page).to have_content('Print tube labels')
    end
  end
end
