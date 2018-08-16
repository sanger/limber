# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Multi plate pooling', js: true do
  has_a_working_api

  let(:user_uuid)         { SecureRandom.uuid }
  let(:user)              { json :user, uuid: user_uuid }
  let(:user_swipecard)    { 'abcdef' }

  let(:plate_barcode_1)   { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:plate_uuid)        { SecureRandom.uuid }
  let(:example_plate)     do
    json :plate_for_pooling,
         barcode_number: 1,
         state: 'passed',
         uuid: plate_uuid,
         purpose_uuid: 'stock-plate-purpose-uuid'
  end

  let(:plate_barcode_2)   { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:plate_uuid_2)      { SecureRandom.uuid }
  let(:example_plate_2)   do
    json :plate_for_pooling,
         barcode_number: 2,
         state: 'passed',
         uuid: plate_uuid_2,
         purpose_uuid: 'stock-plate-purpose-uuid'
  end

  let(:child_plate_uuid) { SecureRandom.uuid }
  let(:child_plate) { json :plate, purpose_uuid: 'child-purpose-0', purpose_name: 'Pool Plate', uuid: child_plate_uuid }

  let!(:pooled_plate_creation_request) do
    stub_api_post(
      'pooled_plate_creations',
      payload: {
        pooled_plate_creation: {
          user: user_uuid,
          child_purpose: 'child-purpose-0',
          parents: [plate_uuid, plate_uuid_2]
        }
      },
      body: json(:plate_creation, child_uuid: child_plate_uuid)
    )
  end

  let!(:bulk_transfer_request) do
    stub_api_post(
      'bulk_transfers',
      payload: {
        bulk_transfer: {
          user: user_uuid,
          well_transfers: [
            {
              'source_uuid' => plate_uuid,
              'source_location' => 'A1',
              'destination_uuid' => child_plate_uuid,
              'destination_location' => 'A1'
            },
            {
              'source_uuid' => plate_uuid,
              'source_location' => 'B1',
              'destination_uuid' => child_plate_uuid,
              'destination_location' => 'A1'
            },
            {
              'source_uuid' => plate_uuid_2,
              'source_location' => 'A1',
              'destination_uuid' => child_plate_uuid,
              'destination_location' => 'B1'
            },
            {
              'source_uuid' => plate_uuid_2,
              'source_location' => 'B1',
              'destination_uuid' => child_plate_uuid,
              'destination_location' => 'B1'
            }
          ]
        }
      },
      body: json(:plate_creation, child_uuid: child_plate_uuid)
    )
  end

  background do
    Settings.purposes = {}
    Settings.purposes['stock-plate-purpose-uuid'] = build :purpose_config
    Settings.purposes['child-purpose-0'] = build :purpose_config, creator_class: 'LabwareCreators::MultiPlatePool',
                                                                  name: 'Pool Plate',
                                                                  parents: ['Pooled example']
    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    # We'll look up both plates.
    stub_asset_search(plate_barcode_1, example_plate)
    stub_asset_search(plate_barcode_2, example_plate_2)

    stub_api_get(plate_uuid, body: example_plate)
    stub_api_get(plate_uuid, 'wells', body: json(:well_collection, aliquot_factory: :tagged_aliquot))

    stub_api_get(plate_uuid_2, body: example_plate_2)
    stub_api_get(plate_uuid_2, 'wells', body: json(:well_collection, aliquot_factory: :tagged_aliquot))

    stub_api_get(child_plate_uuid, body: child_plate)
    stub_api_get(child_plate_uuid, 'wells', body: json(:well_collection, aliquot_factory: :tagged_aliquot))

    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
  end

  scenario 'creates multiple plates' do
    fill_in_swipecard_and_barcode(user_swipecard, plate_barcode_1)
    plate_title = find('#plate-title')
    expect(plate_title).to have_text('Pooled example')
    click_on('Add an empty Pool Plate plate')
    scan_in('Plate 1', with: plate_barcode_1)
    scan_in('Plate 2', with: plate_barcode_2)
    # Trigger a blur by filling in the next box
    scan_in('Plate 3', with: '')
    expect(page).to have_content('DN1: A1, B1')
    expect(page).to have_content('DN2: A1, B1')
    click_on('Make Pre-Cap pool Plate')
    expect(page).to have_text('New empty labware added to the system')
    expect(pooled_plate_creation_request).to have_been_made
    expect(bulk_transfer_request).to have_been_made
    expect(page).to have_text('Pool Plate')
  end
end
