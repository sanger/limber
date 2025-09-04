# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Creating a plate with bait', :js do
  has_a_working_api
  let(:user_uuid) { 'user-uuid' }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode) { example_plate.barcode.machine }
  let(:plate_uuid) { SecureRandom.uuid }
  let(:requests) do
    Array.new(6) { |i| create :library_request, state: 'started', uuid: "request-#{i}", submission_id: '2' }
  end
  let(:example_plate) do
    create :v2_plate, uuid: plate_uuid, state: 'passed', pool_sizes: [3, 3], barcode_number: 2, outer_requests: requests
  end
  let(:child_plate) { create :v2_plate, uuid: 'child-uuid', state: 'pending', pool_sizes: [3, 3], barcode_number: 3 }

  let(:bait_library_layout) { create :bait_library_layout }

  background do
    create :purpose_config, uuid: 'example-purpose-uuid'
    create :purpose_config, creator_class: 'LabwareCreators::BaitedPlate', name: 'with-baits', uuid: 'child-purpose-0'
    create :pipeline, relationships: { 'example-purpose' => 'with-baits' }

    # We look up the user
    stub_swipecard_search(user_swipecard, user)

    # These stubs are required to render plate show page
    stub_v2_plate(example_plate)
    stub_v2_plate(
      example_plate,
      stub_search: false,
      custom_includes: 'wells.aliquots.request.poly_metadata'
    )
    stub_v2_plate(child_plate)
    stub_v2_plate(
      child_plate,
      stub_search: false,
      custom_includes: 'wells.aliquots.request.poly_metadata'
    )
    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))

    # end of stubs for plate show page

    # These stubs are required to render plate_creation baiting page
    expect_api_v2_posts('BaitLibraryLayout', [{ plate_uuid:, user_uuid: }], [[bait_library_layout]], method: :preview)
    stub_api_v2_post('BaitLibraryLayout')

    # end of stubs for plate_creation baiting page

    # These stubs are required to create a new plate with baits
    stub_api_v2_post('PlateCreation', double(child: child_plate))
    stub_api_v2_post('TransferRequestCollection')

    # end of stubs for creating a new plate with baits

    # Stub the requests for the next plate page
    stub_v2_plate(child_plate)
  end

  scenario 'of a recognised type' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    plate_title = find_by_id('plate-title')
    expect(plate_title).to have_text('example-purpose')
    click_on 'Add an empty with-baits plate'
    expect(page).to have_content('Carefully check the bait layout')
    click_on 'Create plate'
    # rubocop:todo Layout/LineLength
    # I do not check the show page for a new plate, as it will be rendered based on my own stubs only, so it is not very informative
    # rubocop:enable Layout/LineLength
  end
end
