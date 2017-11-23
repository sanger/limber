# frozen_string_literal: true

module FeatureHelpers
  def stub_search_and_single_result(search, query, result = nil)
    search_uuid = search.downcase.tr(' ', '-')
    search_url = 'http://example.com:3000/' + search_uuid
    Settings.searches[search] = search_uuid
    stub_api_get(search_uuid, body: json(:swipecard_search, uuid: search_uuid))
    if result.present?
      stub_api_post(search_uuid, 'first', status: 301, payload: query, body: result)
    else
      stub_request(:post, search_url + '/first')
        .with(body: query.to_json)
        .to_raise(Sequencescape::Api::ResourceNotFound)
    end
  end

  def stub_search_and_multi_result(search, query, result)
    search_uuid = search.downcase.tr(' ', '-')
    search_url = 'http://example.com:3000/' + search_uuid
    Settings.searches[search] = search_uuid
    stub_api_get(search_uuid, body: json(:swipecard_search, uuid: search_uuid))
    stub_api_post(search_uuid, 'all', status: 301, payload: query, body: { searches: result }.to_json )
  end

  def stub_swipecard_search(swipecard, user)
    stub_search_and_single_result(
      'Find user by swipecard code',
      { 'search' => { 'swipecard_code' => swipecard } },
      user
    )
  end

  def stub_asset_search(barcode, asset)
    if asset.is_a?(Array)
      stub_search_and_multi_result(
        'Find assets by barcode',
        { 'search' => { 'barcode' => barcode } },
        asset
      )
    else
      stub_search_and_single_result(
        'Find assets by barcode',
        { 'search' => { 'barcode' => barcode } },
        asset
      )
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

  def ean13(number, prefix = 'DN')
    SBCF::SangerBarcode.new(prefix: prefix, number: number).machine_barcode.to_s
  end
end
