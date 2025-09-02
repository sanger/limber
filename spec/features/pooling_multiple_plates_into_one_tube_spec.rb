# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Pooling multiple plates into a tube', :js do
  has_a_working_api

  let(:user_uuid) { SecureRandom.uuid }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }

  let(:plate_barcode_1) { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).human_barcode }
  let(:plate_uuid) { 'plate-1' }
  let(:example_plate) do
    create(
      :v2_plate,
      barcode_number: 1,
      state: 'passed',
      uuid: plate_uuid,
      well_factory: :v2_tagged_well,
      pool_sizes: [96]
    )
  end
  let(:example_plate_listed) do
    create(:v2_plate, :has_pooling_metadata, { barcode_number: 1, state: 'passed', uuid: plate_uuid })
  end

  let(:plate_barcode_2) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).human_barcode }
  let(:plate_uuid_2) { 'plate-2' }

  let(:example_plate_2) do
    create(
      :v2_plate,
      barcode_number: 2,
      state: 'passed',
      uuid: plate_uuid_2,
      well_factory: :v2_tagged_well,
      pool_sizes: [96]
    )
  end
  let(:example_plate_2_listed) do
    create(:v2_plate, :has_pooling_metadata, { barcode_number: 2, state: 'passed', uuid: plate_uuid_2 })
  end

  let(:plate_barcode_3) { SBCF::SangerBarcode.new(prefix: 'DN', number: 3).human_barcode }
  let(:plate_uuid_3) { 'plate-3' }

  let(:example_plate_3) do
    create(
      :v2_plate,
      barcode_number: 3,
      state: 'passed',
      uuid: plate_uuid_3,
      wells: example_plate.wells,
      pool_sizes: [96]
    )
  end
  let(:example_plate_3_listed) do
    create(:v2_plate, :has_pooling_metadata, { barcode_number: 3, state: 'passed', uuid: plate_uuid_3 })
  end

  let(:parent_uuid) { plate_uuid }
  let(:child_tube) { create :v2_tube, purpose_uuid: 'child-purpose-0', purpose_name: 'Pool tube' }

  let(:specific_tubes_attributes) do
    [{ uuid: child_tube.purpose.uuid, parent_uuids: [parent_uuid], child_tubes: [child_tube], tube_attributes: [{}] }]
  end

  # Used to fetch the pools. This is the kind of thing we could pass through from a custom form
  let!(:stub_barcode_searches) do
    stub_asset_v2_search([plate_barcode_1, plate_barcode_2], [example_plate_listed, example_plate_2_listed])
  end

  let(:transfers_attributes) do
    [plate_uuid, plate_uuid_2].map do |source_uuid|
      {
        arguments: {
          user_uuid: user_uuid,
          source_uuid: source_uuid,
          destination_uuid: child_tube.uuid,
          transfer_template_uuid: 'whole-plate-to-tube'
        }
      }
    end
  end

  background do
    create :purpose_config, uuid: 'example-purpose-uuid', name: 'purpose-config'
    create :pooled_tube_from_plates_purpose_config, uuid: 'child-purpose-0'
    create :pipeline, relationships: { 'example-purpose' => 'Pool tube' }

    # We look up the user
    stub_swipecard_search(user_swipecard, user)

    # We'll look up both plates.

    # We have a basic inbox search running
    stub_find_all(
      :plates,
      { state: ['passed'], purpose_name: ['purpose-config'], include_used: false },
      [example_plate_listed, example_plate_2_listed]
    )

    stub_v2_plate(example_plate)
    stub_v2_tube(child_tube)
    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))
  end

  scenario 'creates multiple plates' do
    stub_v2_plate(example_plate_2)

    expect_specific_tube_creation
    expect_transfer_creation

    fill_in_swipecard_and_barcode(user_swipecard, plate_barcode_1)
    plate_title = find_by_id('plate-title')
    expect(plate_title).to have_text('example-purpose')
    click_on('Add an empty Pool tube tube')
    scan_in('Plate 1', with: plate_barcode_1)
    scan_in('Plate 2', with: plate_barcode_2)

    # Trigger a blur by filling in the next box
    scan_in('Plate 3', with: '')
    click_on('Make Pool')
    expect(page).to have_text('New empty labware added to the system')
    expect(page).to have_text('Pool tube')
  end

  scenario 'detects tag clash' do
    stub_v2_plate(example_plate_3)

    fill_in_swipecard_and_barcode(user_swipecard, plate_barcode_1)
    plate_title = find_by_id('plate-title')
    expect(plate_title).to have_text('example-purpose')
    click_on('Add an empty Pool tube tube')
    scan_in('Plate 1', with: plate_barcode_1)
    scan_in('Plate 3', with: plate_barcode_3)

    expect(page).to have_text(
      'The scanned plate contains tags that would clash with those in other plates in the pool. ' \
      'Tag clashes found between: DN1 (DN1S) and DN3 (DN3U)'
    )

    # removes the error message if another scan is made (NB. currently validation and messages relate to
    # just the currently scanned labware field, the code does NOT re-validate all the scanned fields)
    scan_in('Plate 3', with: '')

    expect(page).to have_no_text(
      'The scanned plate contains tags that would clash with those in other plates in the pool.'
    )
  end
end
