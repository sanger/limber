# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Multi plate pooling', :js do
  let(:user_uuid) { SecureRandom.uuid }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }

  let(:plate_barcode_1) { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).human_barcode }
  let(:plate_uuid) { 'plate-1-uuid' }
  let(:example_plate) do
    create :v2_plate_for_pooling,
           barcode_number: 1,
           state: 'passed',
           well_states: %w[passed failed],
           uuid: plate_uuid,
           well_factory: :v2_tagged_well,
           purpose_uuid: 'stock-plate-purpose-uuid'
  end

  let(:plate_barcode_2) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).human_barcode }
  let(:plate_uuid_2) { 'plate-2-uuid' }
  let(:example_plate_2) do
    create :v2_plate_for_pooling,
           barcode_number: 2,
           pool_sizes: [2, 2],
           library_state: %w[started passed],
           state: 'passed',
           uuid: plate_uuid_2,
           well_factory: :v2_tagged_well,
           purpose_uuid: 'stock-plate-purpose-uuid'
  end

  let(:child_plate) { create :v2_plate, purpose_name: 'Pool Plate', barcode_number: 3 }

  let(:bulk_transfer_attributes) do
    [
      {
        user_uuid: user_uuid,
        well_transfers: [
          {
            'source_uuid' => plate_uuid,
            'source_location' => 'A1',
            'destination_uuid' => child_plate.uuid,
            'destination_location' => 'A1'
          },
          {
            'source_uuid' => plate_uuid_2,
            'source_location' => 'A1',
            'destination_uuid' => child_plate.uuid,
            'destination_location' => 'B1'
          },
          {
            'source_uuid' => plate_uuid_2,
            'source_location' => 'B1',
            'destination_uuid' => child_plate.uuid,
            'destination_location' => 'B1'
          }
        ]
      }
    ]
  end

  let(:pooled_plates_attributes) do
    [{ child_purpose_uuid: child_plate.purpose.uuid, parent_uuids: [plate_uuid, plate_uuid_2], user_uuid: user_uuid }]
  end

  background do
    create :purpose_config, uuid: 'stock-plate-purpose-uuid'
    create :purpose_config,
           creator_class: 'LabwareCreators::MultiPlatePool',
           name: 'Pool Plate',
           uuid: child_plate.purpose.uuid
    create :pipeline, relationships: { 'Pooled example' => 'Pool Plate' }

    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    stub_v2_plate(example_plate)
    stub_v2_plate(example_plate)
    stub_v2_plate(example_plate_2)
    stub_v2_plate(child_plate)
    stub_v2_plate(
      example_plate,
      stub_search: false,
      custom_includes: 'wells.aliquots.request.poly_metadata'
    )
    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))
  end

  scenario 'creates multiple plates' do
    expect_bulk_transfer_creation
    expect_pooled_plate_creation

    fill_in_swipecard_and_barcode(user_swipecard, plate_barcode_1)
    plate_title = find_by_id('plate-title')
    expect(plate_title).to have_text('Pooled example')
    click_on('Add an empty Pool Plate plate')
    scan_in('Plate 1', with: plate_barcode_1)
    expect(page).to have_content('DN1: A1')
    expect(page).to have_no_content('DN1: A1, B1')
    scan_in('Plate 2', with: plate_barcode_2)
    expect(page).to have_content('DN2: A1, B1')
    click_on('Make Pre-Cap pool Plate')
    expect(page).to have_text('New empty labware added to the system')
    expect(page).to have_text('Pool Plate')
  end
end
