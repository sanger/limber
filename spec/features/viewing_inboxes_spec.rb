# frozen_string_literal: true

require 'rails_helper'

feature 'Viewing an inbox', js: true do
  has_a_working_api

  let(:user) { json :user }
  let(:user_swipecard) { 'aaa' }

  background do
    stub_swipecard_search(user_swipecard, user)
    Settings.purposes = {
      'uuid-1' => build(:purpose_config),
      'uuid-2' => build(:minimal_purpose_config),
      'uuid-3' => build(:tube_config),
      'uuid-4' => build(:tube_config)
    }
    stub_search_and_multi_result(
      'Find plates',
      { 'search' => {
        states: %w[pending started passed qc_complete failed cancelled],
        plate_purpose_uuids: ['uuid-1', 'uuid-2'],
        show_my_plates_only: false, include_used: false,
        page: 1
      } },
      [associated(:plate, barcode_number: 1), associated(:plate, barcode_number: 3)]
    )
    stub_search_and_multi_result(
      'Find plates',
      { 'search' => {
        states: %w[pending started passed qc_complete failed cancelled],
        plate_purpose_uuids: ['uuid-1', 'uuid-2'],
        show_my_plates_only: true, include_used: false,
        page: 1
      } },
      [associated(:plate, barcode_number: 1)]
    )
    stub_search_and_multi_result(
      'Find tubes',
      { 'search' => {
        states: %w[pending started passed qc_complete failed cancelled],
        tube_purpose_uuids: ['uuid-3', 'uuid-4'],
        include_used: false,
        page: 1
      } },
      [associated(:tube, barcode_number: 2)]
    )
  end

  scenario 'ongoing plates' do
    fill_in_swipecard user_swipecard
    click_button 'Inboxes'
    click_link 'All Ongoing Plates'
    expect(page).to have_content('Ongoing Plates')
    expect(page).to have_content('DN3')
    check 'Show my plates only', allow_label_click: true
    click_on 'Update'
    expect(page).not_to have_content('DN3')
  end

  scenario 'ongoing tubes' do
    fill_in_swipecard user_swipecard
    click_button 'Inboxes'
    click_link 'All Ongoing Tubes'
    expect(page).to have_content('Ongoing Tubes')
    expect(page).to have_content('NT2')
  end
end
