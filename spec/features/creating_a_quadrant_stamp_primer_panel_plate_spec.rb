# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Creating a quadrant stamp primer panel plate', :js do
  has_a_working_api

  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:parent2_uuid) { 'example-plate2-uuid' }
  let(:parent_purpose_uuid) { 'parent-purpose' }
  let(:child_uuid) { 'child-uuid' }
  let(:parent) do
    create :v2_plate_with_primer_panels,
           barcode_number: '2',
           uuid: parent_uuid,
           pool_sizes: [10],
           well_count: 10,
           purpose_uuid: parent_purpose_uuid,
           state: 'passed',
           purpose_name: 'Primer Panel example'
  end
  let(:parent1_barcode) { parent.barcode.machine }
  let(:parent2) do
    create :v2_plate_with_primer_panels,
           barcode_number: '3',
           uuid: parent2_uuid,
           pool_sizes: [10],
           well_count: 10,
           purpose_uuid: parent_purpose_uuid,
           state: 'passed',
           purpose_name: 'Primer Panel example'
  end
  let(:child_plate) { create :v2_plate, uuid: child_uuid, barcode_number: '4', size: 384 }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  background do
    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))
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
