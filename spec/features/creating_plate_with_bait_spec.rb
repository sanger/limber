# frozen_string_literal: true

require 'rails_helper'

feature 'Creating a plate with bait', js: true do
  has_a_working_api
  let(:user_uuid)             { 'user-uuid' }
  let(:user)                  { json :user, uuid: user_uuid }
  let(:user_swipecard)        { 'abcdef' }
  let(:plate_barcode)         { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:plate_uuid)            { SecureRandom.uuid }
  let(:child_purpose_uuid)    { 'child-purpose-0' }
  let(:example_plate)         { json :plate, uuid: plate_uuid, state: 'passed', pool_sizes: [3, 3] }
  let(:child_plate)         { json :plate, uuid: 'child-uuid', state: 'pending', pool_sizes: [3, 3] }
  let(:transfer_template_uuid) { 'transfer-1-12' }
  let(:transfer_template) { json :transfer_template, uuid: transfer_template_uuid }

  background do
    Settings.purposes = {}
    Settings.purposes['example-purpose-uuid'] = build :purpose_config
    Settings.purposes['child-purpose-0'] = build :purpose_config, creator_class: 'LabwareCreators::BaitedPlate',
                                                                  name: 'with-baits',
                                                                  parents: ['example-purpose']
    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    # We lookup the plate
    stub_asset_search(plate_barcode, example_plate)

    # These stube are required to render plate show page
    stub_api_get(plate_uuid, body: example_plate)
    stub_api_get(plate_uuid, 'wells', body: json(:well_collection))
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
    # end of stubs for plate show page

    # These stubs are required to render plate_creation baiting page
    stub_api_post('bait_library_layouts', 'preview', body: json(:bait_library_layout), payload: { bait_library_layout: { plate: plate_uuid, user: user_uuid } })
    # end of stubs for plate_creation baiting page

    # These stubs are required to create a new plate with baits
    stub_api_post('plate_creations', body: json(:plate_creation), payload: { plate_creation: { parent: plate_uuid, user: user_uuid, child_purpose: child_purpose_uuid } })
    stub_api_get(transfer_template_uuid, body: transfer_template)
    stub_api_post(transfer_template_uuid, body: json(:transfer), payload: { transfer: { source: plate_uuid, destination: 'child-uuid', user:  user_uuid } })
    stub_api_post('bait_library_layouts', body: json(:bait_library_layout), payload: { bait_library_layout: { plate: 'child-uuid', user: user_uuid } })
    # end of stubs for creating a new plate with baits
    # Stub the requests for the next plate page
    stub_api_get('child-uuid', body: child_plate)
    stub_api_get('child-uuid', 'wells', body: json(:well_collection))
  end

  scenario 'of a recognised type' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    plate_title = find('#plate-title')
    expect(plate_title).to have_text('example-purpose')
    click_on 'Add an empty with-baits plate'
    expect(page).to have_content('Carefully check the bait layout')
    click_on 'Create plate'
    # I do not check the show page for a new plate, as it will be rendered based on my own stubs only, so it is not very informative
  end
end
