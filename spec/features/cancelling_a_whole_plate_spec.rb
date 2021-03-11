# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Cancelling a whole plate', js: true do
  has_a_working_api

  let(:user_uuid)      { 'user-uuid' }
  let(:user)           { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode)  { example_plate.barcode.human }
  let(:plate_uuid)     { SecureRandom.uuid }
  let(:wells) do
    [
      create(:v2_well, location: 'A1', state: 'passed'),
      create(:v2_well, location: 'B1', state: 'passed'),
      create(:v2_well, location: 'A2', state: 'passed'),
      create(:v2_well, location: 'B2', state: 'failed'),
      create(:v2_well, location: 'A3', state: 'passed')
    ]
  end
  let(:example_plate) do
    create :v2_plate, uuid: plate_uuid, purpose_uuid: 'stock-plate-purpose-uuid', state: 'passed', wells: wells
  end

  let!(:state_change_request) do
    stub_api_post(
      'state_changes',
      payload: {
        'state_change' => {
          user: user_uuid,
          target: plate_uuid,
          contents: nil,
          target_state: 'cancelled',
          reason: 'Not required',
          customer_accepts_responsibility: nil
        }
      },
      body: '{}' # We don't care about the response
    )
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
      stub_v2_plate(example_plate)
    end
    # stub_api_get(plate_uuid, body: example_plate)
    stub_api_get(plate_uuid, 'wells',
                 body: json(:well_collection, default_state: 'passed', custom_state: { 'B2' => 'failed' }))
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
  end

  scenario 'failing a plate' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode

    # Spotted a potential bug where we could accidentally persist details
    # from the failure tab if we select that first and change our minds. So
    # we'll explicitly check that

    within_fieldset('Change state to') do
      choose('failed', allow_label_click: true)
    end

    check('Still charge customer')

    within_fieldset('Change state to') do
      choose('cancelled', allow_label_click: true)
    end

    select('Not required', from: 'Reason for cancellation')

    click_on('Cancel Labware')

    expect(find('#flashes')).to have_content("Labware: #{plate_barcode} has been changed to a state of Cancelled.")
    expect(state_change_request).to have_been_made
  end
end
