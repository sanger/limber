# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Creating a quadrant stamp plate', js: true do
  has_a_working_api

  let(:user_uuid)         { SecureRandom.uuid }
  let(:user)              { create :user, uuid: user_uuid }
  let(:user_swipecard)    { 'abcdef' }

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:parent2_uuid) { 'example-plate2-uuid' }
  let(:parent_purpose_uuid) { 'parent-purpose' }
  let(:child_uuid) { 'child-uuid' }
  let(:requests) { Array.new(96) { |i| create :gbs_library_request, state: 'started', uuid: "request-#{i}" } }
  let(:requests2) { Array.new(96) { |i| create :gbs_library_request, state: 'started', uuid: "request-#{i}" } }
  let(:parent) do
    create :v2_plate_with_primer_panels,
           barcode_number: '2', uuid: parent_uuid,
           outer_requests: requests, well_count: 10,
           purpose_uuid: parent_purpose_uuid, state: 'passed',
           purpose_name: 'Primer Panel example'
  end
  let(:parent1_barcode) { parent.barcode.machine }
  let(:parent2) do
    create :v2_plate_with_primer_panels,
           barcode_number: '3', uuid: parent2_uuid,
           outer_requests: requests2, well_count: 10,
           purpose_uuid: parent_purpose_uuid, state: 'passed',
           purpose_name: 'Primer Panel example'
  end
  let(:parent2_barcode) { parent2.barcode.machine }
  let(:child_plate) { create :v2_plate, uuid: child_uuid, barcode_number: '4', size: 384 }
  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let!(:pooled_plate_creation_request) do
    stub_api_post(
      'pooled_plate_creations',
      payload: {
        pooled_plate_creation: {
          user: user_uuid,
          child_purpose: child_purpose_uuid,
          parents: [parent_uuid, parent2_uuid]
        }
      },
      body: json(:plate_creation, child_uuid: child_uuid)
    )
  end

  let(:transfer_requests) do
    [
      { source_asset: '2-well-A1', outer_request: 'request-0', target_asset: '4-well-A1' },
      { source_asset: '2-well-B1', outer_request: 'request-1', target_asset: '4-well-C1' },
      { source_asset: '2-well-C1', outer_request: 'request-2', target_asset: '4-well-E1' },
      { source_asset: '2-well-D1', outer_request: 'request-3', target_asset: '4-well-G1' },
      { source_asset: '2-well-E1', outer_request: 'request-4', target_asset: '4-well-I1' },
      { source_asset: '2-well-F1', outer_request: 'request-5', target_asset: '4-well-K1' },
      { source_asset: '2-well-G1', outer_request: 'request-6', target_asset: '4-well-M1' },
      { source_asset: '2-well-H1', outer_request: 'request-7', target_asset: '4-well-O1' },
      { source_asset: '2-well-A2', outer_request: 'request-8', target_asset: '4-well-A3' },
      { source_asset: '2-well-B2', outer_request: 'request-9', target_asset: '4-well-C3' },
      { source_asset: '3-well-A1', outer_request: 'request-0', target_asset: '4-well-B1' },
      { source_asset: '3-well-B1', outer_request: 'request-1', target_asset: '4-well-D1' },
      { source_asset: '3-well-C1', outer_request: 'request-2', target_asset: '4-well-F1' },
      { source_asset: '3-well-D1', outer_request: 'request-3', target_asset: '4-well-H1' },
      { source_asset: '3-well-E1', outer_request: 'request-4', target_asset: '4-well-J1' },
      { source_asset: '3-well-F1', outer_request: 'request-5', target_asset: '4-well-L1' },
      { source_asset: '3-well-G1', outer_request: 'request-6', target_asset: '4-well-N1' },
      { source_asset: '3-well-H1', outer_request: 'request-7', target_asset: '4-well-P1' },
      { source_asset: '3-well-A2', outer_request: 'request-8', target_asset: '4-well-B3' },
      { source_asset: '3-well-B2', outer_request: 'request-9', target_asset: '4-well-D3' }
    ]
  end

  let!(:transfer_creation_request) do
    stub_api_post('transfer_request_collections',
                  payload: { transfer_request_collection: {
                    user: user_uuid,
                    transfer_requests: transfer_requests
                  } },
                  body: '{}')
  end

  let(:parent1_plate_old_api) { json(:plate, barcode_number: '2', state: 'passed', uuid: parent_uuid) }

  background do
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
    create :purpose_config, name: 'Primer Panel example', uuid: parent_purpose_uuid
    create :purpose_config,
           creator_class: 'LabwareCreators::QuadrantStampPrimerPanel',
           name: child_purpose_name,
           uuid: 'child-purpose-0'
    create :pipeline, relationships: { 'Primer Panel example' => child_purpose_name }
    stub_swipecard_search(user_swipecard, user)
    stub_v2_plate(parent)
    stub_v2_plate(parent2)
    stub_v2_plate(child_plate)
    stub_api_get(parent.uuid, body: parent1_plate_old_api)
  end

  scenario 'creates multiple plates' do
    fill_in_swipecard_and_barcode(user_swipecard, parent1_barcode)
    click_on("Add an empty #{child_purpose_name} plate")
    # scan_in('Plate 1', with: parent1_barcode)
    # expect(page).to have_content('DN2')
    # scan_in('Plate 2', with: parent2_barcode)
    # expect(page).to have_content('DN3')
    # click_on("Make #{child_purpose_name} Plate")
    # expect(page).to have_text('New empty labware added to the system')
    # expect(pooled_plate_creation_request).to have_been_made
    # expect(transfer_creation_request).to have_been_made
    # expect(page).to have_text(child_purpose_name)
  end
end
