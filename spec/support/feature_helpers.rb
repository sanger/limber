module FeatureHelpers
  def stub_search_and_single_result(search, query, result)
    search_uuid = search.downcase.tr(' ', '-')
    search_url = 'http://example.com:300/' + search_uuid
    Settings.searches[search] = search_uuid
    stub_request(:get, search_url)
      .to_return(status: 200, body: json(:swipecard_search, uuid: search_uuid), headers: { 'content-type' => 'application/json' })

    stub_request(:post, search_url + '/first')
      .with(body: query.to_json)
      .to_return(status: 301, body: result, headers: { 'content-type' => 'application/json' })
  end
end
