# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeProxyController do
  let(:upstream) { 'http://example.com:3000/api/v2' }

  # Request specs have no direct session access, so stub the login check
  def log_in
    allow_any_instance_of(described_class).to receive(:logged_in?).and_return(true) # rubocop:disable RSpec/AnyInstance
  end

  context 'when not logged in' do
    it 'rejects writes with 401 without calling Sequencescape', :aggregate_failures do
      post '/sequencescape_proxy/comments', params: '{}', headers: { 'Content-Type' => 'application/vnd.api+json' }

      expect(response).to have_http_status(:unauthorized)
      expect(a_request(:any, /example.com/)).not_to have_been_made
    end

    it 'allows reads, so read-only pages work for guests' do
      stub = stub_request(:get, "#{upstream}/labware/1").to_return(status: 200, body: '{}')

      get '/sequencescape_proxy/labware/1'

      expect(stub).to have_been_requested
    end
  end

  context 'when logged in' do
    before { log_in }

    describe 'GET with a query string' do
      let!(:stub) do
        stub_request(:get, "#{upstream}/labware/1?include=comments").with(
          headers: {
            'X-Sequencescape-Client-Id' => 'test'
          }
        ).to_return(status: 200, body: '{"data":{}}', headers: { 'Content-Type' => 'application/vnd.api+json' })
      end

      before { get '/sequencescape_proxy/labware/1?include=comments' }

      it 'sends the request upstream with the API key' do
        expect(stub).to have_been_requested
      end

      it 'returns the upstream status and body', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('{"data":{}}')
        expect(response.media_type).to eq('application/vnd.api+json')
      end
    end

    describe 'POST' do
      it 'forwards the body and returns the upstream status', :aggregate_failures do
        stub =
          stub_request(:post, "#{upstream}/comments").with(
            body: '{"data":{"type":"comments"}}',
            headers: {
              'X-Sequencescape-Client-Id' => 'test'
            }
          ).to_return(status: 201, body: '{"data":{"id":"1"}}')

        post '/sequencescape_proxy/comments',
             params: '{"data":{"type":"comments"}}',
             headers: {
               'Content-Type' => 'application/vnd.api+json'
             }

        expect(stub).to have_been_requested
        expect(response).to have_http_status(:created)
      end
    end

    it 'replaces a client-supplied API key and drops cookies' do
      stub =
        stub_request(:get, "#{upstream}/labware/1").with do |req|
          req.headers['X-Sequencescape-Client-Id'] == 'test' && !req.headers.key?('Cookie')
        end.to_return(status: 200, body: '{}')

      get '/sequencescape_proxy/labware/1', headers: { 'X-Sequencescape-Client-Id' => 'stolen', 'Cookie' => 'a=b' }

      expect(stub).to have_been_requested
    end

    it 'returns 403 for a disallowed path without calling Sequencescape', :aggregate_failures do
      get '/sequencescape_proxy/api_keys'

      expect(response).to have_http_status(:forbidden)
      expect(a_request(:any, /example.com/)).not_to have_been_made
    end

    it 'returns 403 for a disallowed verb' do
      post '/sequencescape_proxy/labware'

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 504 on an upstream timeout' do
      stub_request(:get, "#{upstream}/labware/1").to_raise(Faraday::TimeoutError)
      get '/sequencescape_proxy/labware/1'

      expect(response).to have_http_status(:gateway_timeout)
    end

    it 'returns 502 when the upstream connection fails' do
      stub_request(:get, "#{upstream}/labware/1").to_raise(Faraday::ConnectionFailed)
      get '/sequencescape_proxy/labware/1'

      expect(response).to have_http_status(:bad_gateway)
    end
  end
end
