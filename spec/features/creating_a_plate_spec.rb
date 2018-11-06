# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/shared_tagging_examples'

RSpec.feature 'Creating a plate', js: true, tag_plate: true do
  has_a_working_api
  let(:user_uuid)             { 'user-uuid' }
  let(:user)                  { json :user, uuid: user_uuid }
  let(:user_swipecard)        { 'abcdef' }
  let(:plate_barcode)         { example_plate.barcode.machine }
  let(:plate_uuid)            { SecureRandom.uuid }
  let(:child_purpose_uuid)    { 'child-purpose-0' }
  let(:child_purpose_name)    { 'Basic' }
  let(:pools) { 1 }
  let(:request_type_a) { create :request_type, key: 'rt_a' }
  let(:request_type_b) { create :request_type, key: 'rt_b' }
  let(:request_a) { create :library_request, request_type: request_type_a, uuid: 'request-0' }
  let(:request_b) { create :library_request, request_type: request_type_b, uuid: 'request-2' }
  let(:request_c) { create :library_request, request_type: request_type_a, uuid: 'request-1' }
  let(:request_d) { create :library_request, request_type: request_type_b, uuid: 'request-3' }
  let(:wells) do
    [
      create(:v2_stock_well, uuid: '6-well-A1', location: 'A1', aliquot_count: 1, requests_as_source: [request_a]),
      create(:v2_stock_well, uuid: '6-well-B1', location: 'B1', aliquot_count: 1, requests_as_source: [request_c]),
      create(:v2_stock_well, uuid: '6-well-c1', location: 'C1', aliquot_count: 0, requests_as_source: [])
    ]
  end

  let(:example_plate) do
    create :v2_stock_plate, barcode_number: 6, uuid: plate_uuid, state: 'passed', wells: wells, purpose_name: 'Limber Cherrypicked'
  end

  let(:child_plate) do
    create :v2_plate, uuid: 'child-uuid', barcode_number: 7, state: 'passed', purpose_name: child_purpose_name
  end

  let!(:plate_creation_request) do
    stub_api_post('plate_creations',
                  payload: { plate_creation: {
                    parent: plate_uuid,
                    child_purpose: child_purpose_uuid,
                    user: user_uuid
                  } },
                  body: json(:plate_creation))
  end
  let!(:transfer_creation_request) do
    stub_api_post('transfer_request_collections',
                  payload: { transfer_request_collection: {
                    user: user_uuid,
                    transfer_requests: transfer_requests
                  } },
                  body: '{}')
  end

  let(:transfer_requests) do
    WellHelpers.column_order(96)[0, 2].each_with_index.map do |well_name, index|
      {
        'source_asset' => "6-well-#{well_name}",
        'target_asset' => "7-well-#{well_name}",
        'outer_request' => "request-#{index}"
      }
    end
  end

  let(:child_purpose_config) { { name: child_purpose_name, uuid: 'child-purpose-0', parents: ['Limber Cherrypicked'] } }

  # Setup stubs
  background do
    # Set-up the plate config
    create :purpose_config, uuid: example_plate.purpose.uuid
    create(:purpose_config, child_purpose_config)

    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    # We get the actual plate
    2.times { stub_v2_plate(example_plate) }
    stub_v2_plate(child_plate, stub_search: false)
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
  end

  scenario 'basic plate creation' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    plate_title = find('#plate-title')
    expect(plate_title).to have_text('Limber Cherrypicked')
    click_on('Add an empty Basic plate')
    expect(page).to have_content('New empty labware added to the system.')
  end

  context 'with multiple requests and no config' do
    let(:wells) do
      [
        create(:v2_stock_well, uuid: '6-well-A1', location: 'A1', aliquot_count: 1, requests_as_source: [request_a, request_b]),
        create(:v2_stock_well, uuid: '6-well-B1', location: 'B1', aliquot_count: 1, requests_as_source: [request_c, request_d]),
        create(:v2_stock_well, uuid: '6-well-c1', location: 'C1', aliquot_count: 0, requests_as_source: [])
      ]
    end
    # We'll eventually add in a disambiguation page here
    scenario 'basic plate creation' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find('#plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Basic plate')
      expect(page).to have_content('Cannot create the next piece of labware:')
      expect(page).to have_content('Well filter found 2 eligible requests for A1')
    end
  end

  context 'with multiple requests and config' do
    let(:child_purpose_config) do
      { name: child_purpose_name, uuid: 'child-purpose-0', parents: ['Limber Cherrypicked'], expected_request_types: ['rt_a'] }
    end

    let(:wells) do
      [
        create(:v2_stock_well, uuid: '6-well-A1', location: 'A1', aliquot_count: 1, requests_as_source: [request_a, request_b]),
        create(:v2_stock_well, uuid: '6-well-B1', location: 'B1', aliquot_count: 1, requests_as_source: [request_c, request_d]),
        create(:v2_stock_well, uuid: '6-well-c1', location: 'C1', aliquot_count: 0, requests_as_source: [])
      ]
    end

    scenario 'basic plate creation' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find('#plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Basic plate')
      expect(page).to have_content('New empty labware added to the system.')
    end
  end
end
