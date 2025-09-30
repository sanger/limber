# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Viewing an inbox', :js do
  let(:user) { create :user }
  let(:user_swipecard) { 'aaa' }

  let(:plate_1) { create(:plate, :has_pooling_metadata, barcode_number: 1) }
  let(:plate_2) { create(:plate, :has_pooling_metadata, barcode_number: 2) }
  let(:plate_3) { create(:plate, :has_pooling_metadata, barcode_number: 3) }

  let(:tube_1) { create(:tube, barcode_number: 1) }
  let(:tube_2) { create(:tube, barcode_number: 2) }

  background do
    stub_swipecard_search(user_swipecard, user)
    create(:purpose_config, name: 'purpose-config', uuid: 'purpose-config-uuid')
    create(:minimal_purpose_config, name: 'minimal-purpose-config', uuid: 'minimal-purpose-config-uuid')
    create(:tube_config, name: 'tube-config')

    stub_find_all_with_pagination(
      :plates,
      { state: %w[pending started passed qc_complete failed cancelled], purpose_name: [], include_used: false },
      { page: 1, per_page: 30 },
      [plate_1, plate_2, plate_3]
    )
    stub_find_all_with_pagination(
      :tubes,
      {
        state: %w[pending started passed qc_complete failed cancelled],
        purpose_name: %w[tube-config],
        include_used: false
      },
      { page: 1, per_page: 30 },
      [tube_1, tube_2]
    )
  end

  scenario 'ongoing plates' do
    fill_in_swipecard user_swipecard
    click_button 'Inboxes'
    click_link 'All Ongoing Plates'
    expect(page).to have_content('Ongoing Plates')
    expect(page).to have_content('DN3')
  end

  scenario 'ongoing tubes' do
    fill_in_swipecard user_swipecard
    click_button 'Inboxes'
    click_link 'All Ongoing Tubes'
    expect(page).to have_content('Ongoing Tubes')
    expect(page).to have_content('NT2')
  end
end
