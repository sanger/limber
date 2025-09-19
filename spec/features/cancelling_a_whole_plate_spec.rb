# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Cancelling a whole plate', :js do
  let(:user_uuid) { 'user-uuid' }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode) { example_plate.barcode.human }
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
    create :plate, uuid: plate_uuid, purpose_uuid: 'stock-plate-purpose-uuid', state: 'passed', wells: wells
  end

  let(:state_changes_attributes) do
    [
      {
        contents: %w[A1 B1 A2 A3], # Well B2 was already failed and won't be changed to cancelled
        customer_accepts_responsibility: nil,
        reason: 'Not required',
        target_state: 'cancelled',
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

    # We get the plate several times, for both the initial find, and the redirect post state change.
    stub_plate(example_plate)
    stub_plate(
      example_plate,
      stub_search: false,
      custom_includes: 'wells.aliquots.request.poly_metadata'
    )

    # We get the printers
    stub_barcode_printers(create_list(:plate_barcode_printer, 3))
  end

  scenario 'from the interface' do
    expect_state_change_creation

    fill_in_swipecard_and_barcode user_swipecard, plate_barcode

    # Spotted a potential bug where we could accidentally persist details
    # from the failure tab if we select that first and change our minds. So
    # we'll explicitly check that
    within_fieldset('Change state to') { choose('failed', allow_label_click: true) }

    check('Still charge customer')

    within_fieldset('Change state to') { choose('cancelled', allow_label_click: true) }

    select('Not required', from: 'Reason for cancellation')

    click_on('Cancel Labware')

    expect(find_by_id('flashes')).to have_content("Labware: #{plate_barcode} has been changed to a state of Cancelled.")
  end
end
