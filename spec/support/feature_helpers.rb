# frozen_string_literal: true
module FeatureHelpers
  def stub_search_and_single_result(search, query, result = nil)
    search_uuid = search.downcase.tr(' ', '-')
    search_url = 'http://example.com:3000/' + search_uuid
    Settings.searches[search] = search_uuid
    stub_request(:get, search_url)
      .to_return(status: 200, body: json(:swipecard_search, uuid: search_uuid), headers: { 'content-type' => 'application/json' })

    if result.present?
      stub_request(:post, search_url + '/first')
        .with(body: query.to_json)
        .to_return(status: 301, body: result, headers: { 'content-type' => 'application/json' })
    else
      stub_request(:post, search_url + '/first')
        .with(body: query.to_json)
        .to_raise(Sequencescape::Api::ResourceNotFound)
    end
  end

  def fill_in_swipecard_and_barcode(swipecard, barcode)
    visit root_path

    within '.content-main' do
      fill_in 'User Swipecard', with: swipecard
      find_field('User Swipecard').send_keys :enter
      expect(page).to have_content('Jane Doe')
      fill_in 'Plate or Tube Barcode', with: barcode
      find_field('Plate or Tube Barcode').send_keys :enter
    end
  end

  def fill_in_swipecard(swipecard)
    visit root_path

    within '.content-main' do
      fill_in 'User Swipecard', with: swipecard
      find_field('User Swipecard').send_keys :enter
    end
  end
end
