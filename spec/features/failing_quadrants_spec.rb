# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Failing quadrants', :js do
  let(:user_uuid) { 'user-uuid' }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode) { example_plate.barcode.machine }
  let(:plate_uuid) { SecureRandom.uuid }
  let(:wells) do
    [
      create(:well, location: 'A1', state: 'passed'),
      create(:well, location: 'B1', state: 'passed'),
      create(:well, location: 'A2', state: 'passed'),
      create(:well, location: 'B2', state: 'failed'),
      create(:well, location: 'A3', state: 'passed')
    ]
  end
  let(:example_plate) do
    create :plate,
           uuid: plate_uuid,
           purpose_uuid: 'stock-plate-purpose-uuid',
           state: 'passed',
           wells: wells,
           size: 384
  end

  let(:state_changes_attributes) do
    [
      {
        contents: %w[A1 A3],
        customer_accepts_responsibility: nil,
        reason: 'Individual Well Failure',
        target_state: 'failed',
        target_uuid: plate_uuid,
        user_uuid: user_uuid
      }
    ]
  end

  # Setup stubs
  background do
    # Set-up the plate config
    create :purpose_config, uuid: 'stock-plate-purpose-uuid'
    create :purpose_config, uuid: 'child-purpose-0'

    # We look up the user
    stub_swipecard_search(user_swipecard, user)

    # We get the actual plate

    2.times do # For both the initial find, and the redirect post state change
      stub_plate(example_plate)
      stub_plate(
        example_plate,
        stub_search: false,
        custom_includes: 'wells.aliquots.request.poly_metadata'
      )
    end

    stub_barcode_printers(create_list(:plate_barcode_printer, 3))
  end

  scenario 'failing wells' do
    expect_state_change_creation

    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    click_on('Fail Wells')

    click_on('Select Quadrant 1')
    click_on('Select Quadrant 4')

    click_on('Fail selected wells')
    expect(find_by_id('flashes')).to have_content('Selected wells have been failed')
  end
end
