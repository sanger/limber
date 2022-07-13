# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Cancelling a whole plate', js: true do
  has_a_working_api

  let(:user_uuid) { 'user-uuid' }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode) { example_plate.barcode.human }
  let(:plate_uuid) { SecureRandom.uuid }
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
  let(:old_api_example_plate) do
    json :plate, barcode_number: example_plate.labware_barcode.number, uuid: plate_uuid, state: 'passed'
  end

  let!(:state_change_request) do
    stub_api_post(
      'state_changes',
      payload: {
        'state_change' => {
          user: user_uuid,
          target: plate_uuid,
          contents: %w[
            A1
            B1
            C1
            D1
            E1
            F1
            G1
            H1
            A2
            C2
            D2
            E2
            F2
            G2
            H2
            A3
            B3
            C3
            D3
            E3
            F3
            G3
            H3
            A4
            B4
            C4
            D4
            E4
            F4
            G4
            H4
            A5
            B5
            C5
            D5
            E5
            F5
            G5
            H5
            A6
            B6
            C6
            D6
            E6
            F6
            G6
            H6
            A7
            B7
            C7
            D7
            E7
            F7
            G7
            H7
            A8
            B8
            C8
            D8
            E8
            F8
            G8
            H8
            A9
            B9
            C9
            D9
            E9
            F9
            G9
            H9
            A10
            B10
            C10
            D10
            E10
            F10
            G10
            H10
            A11
            B11
            C11
            D11
            E11
            F11
            G11
            H11
            A12
            B12
            C12
            D12
            E12
            F12
            G12
            H12
          ],
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

    # We get the plate several times, for both the initial find, and the redirect post state change (api 1 and 2)
    stub_v2_plate(example_plate)
    stub_api_get(plate_uuid, body: old_api_example_plate)
    stub_api_get(
      plate_uuid,
      'wells',
      body: json(:well_collection, default_state: 'passed', custom_state: { 'B2' => 'failed' })
    )

    # We get the printers
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
  end

  scenario 'from the interface' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode

    # Spotted a potential bug where we could accidentally persist details
    # from the failure tab if we select that first and change our minds. So
    # we'll explicitly check that
    within_fieldset('Change state to') { choose('failed', allow_label_click: true) }

    check('Still charge customer')

    within_fieldset('Change state to') { choose('cancelled', allow_label_click: true) }

    select('Not required', from: 'Reason for cancellation')

    click_on('Cancel Labware')

    expect(find('#flashes')).to have_content("Labware: #{plate_barcode} has been changed to a state of Cancelled.")
    expect(state_change_request).to have_been_made
  end
end
