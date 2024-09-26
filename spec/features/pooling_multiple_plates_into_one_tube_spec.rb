# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Pooling multiple plates into a tube', js: true do
  has_a_working_api

  let(:user_uuid) { SecureRandom.uuid }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }

  let(:plate_barcode_1) { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).human_barcode }
  let(:plate_uuid) { 'plate-1' }
  let(:example_plate_args) { [:plate, { barcode_number: 1, state: 'passed', uuid: plate_uuid }] }
  let(:example_plate) { json(*example_plate_args) }
  let(:example_plate_new_api) do
    create(
      :v2_plate,
      barcode_number: 1,
      state: 'passed',
      uuid: plate_uuid,
      well_factory: :v2_tagged_well,
      pool_sizes: [96]
    )
  end
  let(:example_plate_listed) { associated(*example_plate_args) }

  let(:plate_barcode_2) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).human_barcode }
  let(:plate_uuid_2) { 'plate-2' }
  let(:example_plate2_args) { [:plate, { barcode_number: 2, state: 'passed', uuid: plate_uuid_2 }] }

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
  let(:example_plate_2_listed) { associated(*example_plate2_args) }

  let(:plate_barcode_3) { SBCF::SangerBarcode.new(prefix: 'DN', number: 3).human_barcode }
  let(:plate_uuid_3) { 'plate-3' }
  let(:example_plate3_args) { [:plate, { barcode_number: 3, state: 'passed', uuid: plate_uuid_3 }] }

  let(:example_plate_3) do
    create(
      :v2_plate,
      barcode_number: 3,
      state: 'passed',
      uuid: plate_uuid_3,
      wells: example_plate_new_api.wells,
      pool_sizes: [96]
    )
  end
  let(:example_plate_3_listed) { associated(*example_plate3_args) }

  let(:child_tube_uuid) { 'tube-0' }
  let(:child_tube) do
    create :v2_tube, purpose_uuid: 'child-purpose-0', purpose_name: 'Pool tube', uuid: child_tube_uuid
  end

  let(:tube_creation_request_uuid) { SecureRandom.uuid }

  let!(:tube_creation_request) do
    # TODO: In reality we want to link in all four parents.
    stub_api_post(
      'specific_tube_creations',
      payload: {
        specific_tube_creation: {
          user: user_uuid,
          parent: plate_uuid,
          child_purposes: ['child-purpose-0'],
          tube_attributes: [{ name: 'DN2+' }]
        }
      },
      body: json(:specific_tube_creation, uuid: tube_creation_request_uuid, children_count: 1)
    )
  end

  # Find out what tubes we've just made!
  let!(:tube_creation_children_request) do
    stub_api_get(tube_creation_request_uuid, 'children', body: json(:tube_collection, names: ['DN1+']))
  end

  # Used to fetch the pools. This is the kind of thing we could pass through from a custom form
  let!(:stub_barcode_searches) do
    stub_asset_search([plate_barcode_1, plate_barcode_2], [example_plate_listed, example_plate_2_listed])
  end

  let(:well_set_a) { json(:well_collection, aliquot_factory: :tagged_aliquot) }

  background do
    create :purpose_config, uuid: 'example-purpose-uuid'
    create :pooled_tube_from_plates_purpose_config, uuid: 'child-purpose-0'
    create :pipeline, relationships: { 'example-purpose' => 'Pool tube' }

    # We look up the user
    stub_swipecard_search(user_swipecard, user)

    # We'll look up both plates.

    # We have a basic inbox search running
    stub_search_and_multi_result(
      'Find plates',
      {
        'search' => {
          states: ['passed'],
          plate_purpose_uuids: ['example-purpose-uuid'],
          show_my_plates_only: false,
          include_used: false,
          page: 1
        }
      },
      [example_plate_listed, example_plate_2_listed]
    )

    stub_v2_plate(example_plate_new_api)

    stub_v2_plate(example_plate_new_api)

    stub_api_get(plate_uuid, body: example_plate)
    stub_api_get(plate_uuid, 'wells', body: well_set_a)

    stub_v2_tube(child_tube)

    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))
  end

  scenario 'creates multiple plates' do
    stub_v2_plate(example_plate_2)

    expect_api_v2_posts(
      'Transfer',
      [plate_uuid, plate_uuid_2].map do |source_uuid|
        {
          user_uuid: user_uuid,
          source_uuid: source_uuid,
          destination_uuid: 'tube-0',
          transfer_template_uuid: 'whole-plate-to-tube'
        }
      end
    )

    fill_in_swipecard_and_barcode(user_swipecard, plate_barcode_1)
    plate_title = find('#plate-title')
    expect(plate_title).to have_text('example-purpose')
    click_on('Add an empty Pool tube tube')
    scan_in('Plate 1', with: plate_barcode_1)
    scan_in('Plate 2', with: plate_barcode_2)

    # Trigger a blur by filling in the next box
    scan_in('Plate 3', with: '')
    click_on('Make Pool')
    expect(page).to have_text('New empty labware added to the system')
    expect(page).to have_text('Pool tube')

    # This isn't strictly speaking correct to test. But there isn't a great way
    # of confirming that the right information got passed to the back end otherwise.
    # (Although you expect it to fail on an incorrect request)
    expect(tube_creation_request).to have_been_made
  end

  scenario 'detects tag clash' do
    stub_v2_plate(example_plate_3)
    fill_in_swipecard_and_barcode(user_swipecard, plate_barcode_1)
    plate_title = find('#plate-title')
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

    expect(page).to_not have_text(
      'The scanned plate contains tags that would clash with those in other plates in the pool.'
    )
  end
end
