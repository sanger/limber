# frozen_string_literal: true

module FeatureHelpers # rubocop:todo Metrics/ModuleLength
  def stub_search_and_single_result(search, query, result = nil) # rubocop:todo Metrics/MethodLength
    search_uuid = search.downcase.tr(' ', '-')
    Settings.searches[search] = search_uuid
    stub_api_get(search_uuid, body: json(:swipecard_search, uuid: search_uuid))
    if result.present?
      stub_api_post(search_uuid, 'first', status: 301, payload: query, body: result)
    else
      search_url = "http://example.com:3000/#{search_uuid}"
      stub_request(:post, "#{search_url}/first")
        .with(body: query.to_json)
        .to_raise(Sequencescape::Api::ResourceNotFound)
    end
  end

  def stub_search_and_multi_result(search, query, result)
    search_uuid = search.downcase.tr(' ', '-')
    Settings.searches[search] = search_uuid
    stub_api_get(search_uuid, body: json(:swipecard_search, uuid: search_uuid))
    stub_api_post(search_uuid, 'all', status: 301, payload: query,
                                      body: { size: result.length, searches: result }.to_json)
  end

  def stub_swipecard_search(swipecard, user)
    allow(Sequencescape::Api::V2::User).to receive(:find).with(user_code: swipecard).and_return([user])
  end

  def stub_asset_search(barcode, asset) # rubocop:todo Metrics/MethodLength
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

  def stub_get_labware_metadata(barcode, labware_v1, metadata = nil)
    params = {
      uuid: 'custom_metadatum_collection-uuid'
    }
    params.merge!(metadata) unless metadata.nil?
    stub_asset_search(barcode, labware_v1)
    stub_api_get('custom_metadatum_collection-uuid',
                 body: json(:v1_custom_metadatum_collection, params))
  end

  def stub_create_labware_metadata(barcode, labware_v1, labware_uuid, user_uuid, metadata) # rubocop:todo Metrics/MethodLength
    stub_asset_search(barcode, labware_v1)
    stub_api_post('custom_metadatum_collections',
                  payload: {
                    custom_metadatum_collection: {
                      user: user_uuid,
                      asset: labware_uuid,
                      metadata: metadata
                    }
                  },
                  body: json(:v1_custom_metadatum_collection,
                             uuid: 'custom_metadatum_collection-uuid',
                             metadata: metadata))
  end

  def stub_update_labware_metadata(barcode, labware_v1, user, metadata)
    stub_get_labware_metadata(barcode, labware_v1, metadata)
    stub_api_get('user-uuid', body: user)
    stub_api_get('asset-uuid', body: labware_v1)
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

  # Because wells can get quite small on 384 well plates, we use a tooltip
  # to provide feedback about which well is being hovered over. This is provided
  # by bootstrap: https://getbootstrap.com/docs/4.6/components/tooltips/
  # This finder allows capybara to identify an element by its tooltip
  #
  # @param tooltip [String] The text of the tooltip
  # @param type [String] A selector for the element eg. 'div', '.well'
  #                      'div' by default
  #
  # @return [Capybara::Node::Element] The element found
  #
  def find_with_tooltip(tooltip, type: 'div')
    find("#{type}[data-original-title='#{tooltip}']")
  end
end
