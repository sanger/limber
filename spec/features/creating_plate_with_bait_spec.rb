# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Creating a plate with bait', js: true do
  has_a_working_api
  let(:user_uuid)             { 'user-uuid' }
  let(:user)                  { json :user, uuid: user_uuid }
  let(:user_swipecard)        { 'abcdef' }
  let(:plate_barcode)         { example_plate.barcode.machine }
  let(:plate_uuid)            { SecureRandom.uuid }
  let(:child_purpose_uuid)    { 'child-purpose-0' }
  let(:requests) { Array.new(6) { |i| create :library_request, state: 'started', uuid: "request-#{i}" } }
  let(:example_plate) { create :v2_plate, uuid: plate_uuid, state: 'passed', pool_sizes: [3, 3], barcode_number: 2, outer_requests: requests }
  let(:child_plate) { create :v2_plate, uuid: 'child-uuid', state: 'pending', pool_sizes: [3, 3], barcode_number: 3 }
  let(:transfer_template_uuid) { 'custom-pooling' }
  let(:transfer_template) { json :transfer_template, uuid: transfer_template_uuid }
  let(:expected_transfers) { WellHelpers.stamp_hash(96) }

  let(:transfer_requests) do
    WellHelpers.column_order(96)[0, 6].each_with_index.map do |well_name, index|
      {
        'source_asset' => "2-well-#{well_name}",
        'target_asset' => "3-well-#{well_name}",
        'outer_request' => "request-#{index}"
      }
    end
  end

  background do
    create :purpose_config, uuid: 'example-purpose-uuid'
    create :purpose_config, creator_class: 'LabwareCreators::BaitedPlate',
                            name: 'with-baits',
                            parents: ['example-purpose'],
                            uuid: 'child-purpose-0'
    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    # These stubs are required to render plate show page
    stub_v2_plate(example_plate)
    stub_v2_plate(child_plate)

    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
    # end of stubs for plate show page

    # These stubs are required to render plate_creation baiting page
    stub_api_post('bait_library_layouts', 'preview', body: json(:bait_library_layout), payload: { bait_library_layout: { plate: plate_uuid, user: user_uuid } })
    # end of stubs for plate_creation baiting page

    # These stubs are required to create a new plate with baits
    stub_api_post('plate_creations', body: json(:plate_creation), payload: { plate_creation: { parent: plate_uuid, user: user_uuid, child_purpose: child_purpose_uuid } })
    stub_api_post('transfer_request_collections',
                  payload: { transfer_request_collection: {
                    user: user_uuid,
                    transfer_requests: transfer_requests
                  } },
                  body: '{}')
    stub_api_post('bait_library_layouts', body: json(:bait_library_layout), payload: { bait_library_layout: { plate: 'child-uuid', user: user_uuid } })
    # end of stubs for creating a new plate with baits
    # Stub the requests for the next plate page
    stub_v2_plate(child_plate)
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
