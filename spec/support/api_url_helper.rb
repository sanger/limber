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
    def stub_api_get(*components, status: 200, body:)
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
    def stub_api_post(*components, status: 201, body:, payload:)
      stub_api_modify(*components, status: status, body: body, payload: payload)
    end

    def stub_api_modify(*components, action: :post, status: 201, body:, payload:)
      stub_request(action, api_url_for(*components))
        .with(
          headers: { 'Accept' => 'application/json', 'content-type' => 'application/json' },
          body: payload
        )
        .to_return(
          status: status,
          body: body,
          headers: { 'content-type' => 'application/json' }
        )
    end

    def stub_api_put(*components, body:, payload:)
      stub_api_modify(*components, action: :put, status: 200, body: body, payload: payload)
    end
  end
end

RSpec.configure do |config|
  config.include ApiUrlHelper
  config.include ApiUrlHelper::ClassMethods
end
