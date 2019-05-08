# frozen_string_literal: true

module FeatureHelpers
  def stub_search_and_single_result(search, query, result = nil)
    search_uuid = search.downcase.tr(' ', '-')
    Settings.searches[search] = search_uuid
    stub_api_get(search_uuid, body: json(:swipecard_search, uuid: search_uuid))
    if result.present?
      stub_api_post(search_uuid, 'first', status: 301, payload: query, body: result)
    else
      search_url = 'http://example.com:3000/' + search_uuid
      stub_request(:post, search_url + '/first')
        .with(body: query.to_json)
        .to_raise(Sequencescape::Api::ResourceNotFound)
    end
  end

  def stub_search_and_multi_result(search, query, result)
    search_uuid = search.downcase.tr(' ', '-')
    Settings.searches[search] = search_uuid
    stub_api_get(search_uuid, body: json(:swipecard_search, uuid: search_uuid))
    stub_api_post(search_uuid, 'all', status: 301, payload: query, body: { size: result.length, searches: result }.to_json)
  end

  def stub_swipecard_search(swipecard, user)
    allow(Sequencescape::Api::V2::User).to receive(:find).with(user_code: swipecard).and_return([user])
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

  def stub_get_plate_metadata(barcode, plate_v1, metadata = nil)
    params = {
      uuid: 'custom_metadatum_collection-uuid'
    }
    params.merge!(metadata) unless metadata.nil?
    stub_asset_search(barcode, plate_v1)
    stub_api_get('custom_metadatum_collection-uuid',
                 body: json(:v1_custom_metadatum_collection, params))
  end

  def stub_create_plate_metadata(barcode, plate_v1, plate_uuid, user_uuid, metadata)
    stub_asset_search(barcode, plate_v1)
    stub_api_post('custom_metadatum_collections',
                  payload: {
                    custom_metadatum_collection: {
                      user: user_uuid,
                      asset: plate_uuid,
                      metadata: metadata
                    }
                  },
                  body: json(:v1_custom_metadatum_collection,
                             uuid: 'custom_metadatum_collection-uuid',
                             metadata: metadata))
  end

  def stub_update_plate_metadata(barcode, plate_v1, user, user_uuid, metadata)
    stub_get_plate_metadata(barcode, plate_v1, metadata)
    stub_api_get('user-uuid', body: user)
    stub_api_get('asset-uuid', body: plate_v1)
    stub_api_put('custom_metadatum_collection-uuid',
                 payload: {
                   custom_metadatum_collection: { metadata: metadata }
                 },
                 body: json(:v1_custom_metadatum_collection,
                            uuid: 'custom_metadatum_collection-uuid',
                            metadata: metadata))
  end

  def fill_in_swipecard_and_barcode(swipecard, barcode)
    visit root_path

    within '.content-main' do
      swipe_in 'User Swipecard', with: swipecard
      expect(page).to have_content('Jane Doe')
      scan_in 'Plate or Tube Barcode', with: barcode
    end
  end

  def fill_in_swipecard(swipecard)
    visit root_path

    within '.content-main' do
      swipe_in 'User Swipecard', with: swipecard
      expect(page).to have_content('Jane Doe')
    end
  end

  def scan_in(field, options)
    terminate = options.delete(:terminate) || :tab
    fill_in_with_terminate(terminate, field, options)
  end

  def swipe_in(field, options)
    fill_in_with_terminate(:enter, field, options)
  end

  def fill_in_with_terminate(terminate, field, options)
    fill_in(field, options)
    find_field(field).send_keys terminate
  end

  def ean13(number, prefix = 'DN')
    SBCF::SangerBarcode.new(prefix: prefix, number: number).machine_barcode.to_s
  end
end
