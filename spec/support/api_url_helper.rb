# frozen_string_literal: true

module ApiUrlHelper
  API_ROOT = 'http://example.com:3000'

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def api_root
      API_ROOT
    end

    def api_url_for(*components)
      model = components.shift
      uuid = model.is_a?(String) ? model : model.uuid
      [api_root, uuid, *components].join('/')
    end

    # Generate an API stub for a get request.
    # eg. stub_api_get(plate, 'children', body: json(:plate_collection))
    # stub_api_get(plate_uuid, body: json(:plate))
    # @param [Api::Resource,*String] components one or more components that form the url. Models are converted to their uuid.
    # @param [String] body: named_parameter reflecting the expected response JSON
    # @param [Int] status: the response status, defaults to 200
    # @return mocked_request
    def stub_api_get(*components, status: 200, body: '{}')
      stub_request(:get, api_url_for(*components))
        .with(headers: { 'Accept' => 'application/json' })
        .to_return(
          status: status,
          body: body,
          headers: { 'content-type' => 'application/json' }
        )
    end

    # Generate an API stub for a post request.
    # eg. stub_api_get(plate, 'children', body: json(:plate_collection))
    # stub_api_post('transfer-to-wells-by-submission-uuid',
    #               payload: { transfer: {
    #                 targets: { 'pool-1-uuid' => 'tube-0', 'pool-2-uuid' => 'tube-1' },
    #                 source: parent_uuid,
    #                 user: user_uuid
    #               }},
    #               body: json(:transfer))
    # @param [Api::Resource,*String] components one or more components that form the url. Models are converted to their uuid.
    # @param [String] body: named_parameter reflecting the expected response JSON
    # @param [Hash] payload: the payload of the post request. Hash strongly recommended over raw json
    # @param [Int] status: the response status, defaults to 201
    # @return mocked_request
    def stub_api_post(*components, status: 201, body: '{}', payload: {})
      stub_api_modify(*components, status: status, body: body, payload: payload)
    end

    def stub_api_modify(*components, action: :post, status: 201, body:, payload:)
      Array(body).reduce(
        stub_request(action, api_url_for(*components))
        .with(
          headers: { 'Accept' => 'application/json', 'content-type' => 'application/json' },
          body: payload
        )
      ) do |request, response|
        request.to_return(
          status: status,
          body: response,
          headers: { 'content-type' => 'application/json' }
        )
      end
    end

    def stub_api_put(*components, body:, payload:)
      stub_api_modify(*components, action: :put, status: 200, body: body, payload: payload)
    end

    def stub_api_v2(klass, includes: nil, where:, first: nil, all: nil)
      query_builder = "Sequencescape::Api::V2::#{klass}".constantize
      expect(query_builder).to receive(:includes).with(*includes).and_return(query_builder) if includes
      if all
        expect(query_builder).to receive(:where).with(where).and_return(query_builder)
        expect(query_builder).to receive(:all).and_return(all)
      else
        expect(query_builder).to receive(:find).with(where).and_return(JsonApiClient::ResultSet.new([first]))
      end
    end

    # Builds the basic v2 plate finding query.
    def stub_v2_plate(plate, stub_search: true, custom_query: nil)
      # Stub to v1 api search here as well!
      if stub_search
        stub_asset_search(
          plate.barcode.machine,
          json(:plate, uuid: plate.uuid, purpose_name: plate.purpose.name, purpose_uuid: plate.purpose.uuid)
        )
      end

      if custom_query
        allow(Sequencescape::Api::V2).to receive(custom_query.first).with(*custom_query.last).and_return(plate)
      else
        allow(Sequencescape::Api::V2).to receive(:plate_for_presenter).with(uuid: plate.uuid).and_return(plate)
      end
    end

    # Builds the basic v2 tube finding query.
    def stub_v2_tube(tube, stub_search: true, custom_includes: false)
      # Stub to v1 api search here as well!
      if stub_search
        stub_asset_search(
          tube.barcode.machine,
          json(:tube, uuid: tube.uuid, purpose_name: tube.purpose.name, purpose_uuid: tube.purpose.uuid)
        )
      end
      arguments = custom_includes ? [{ uuid: tube.uuid }, { includes: custom_includes }] : [{ uuid: tube.uuid }]
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(*arguments).and_return(tube)
    end
  end
  extend ClassMethods
end

RSpec.configure do |config|
  config.include ApiUrlHelper
  config.include ApiUrlHelper::ClassMethods
end
