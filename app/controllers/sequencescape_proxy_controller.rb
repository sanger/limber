# frozen_string_literal: true

# Forwards browser requests to the Sequencescape v2 API, adding the API key on the server
# so that it never has to be exposed to the browser. Only requests permitted by
# SequencescapeProxyPolicy are forwarded, and anything other than a read needs a logged-in user
# (read-only Limber pages are viewable without logging in).
class SequencescapeProxyController < ApplicationController
  # Reject (rather than silently null the session of) state-changing requests lacking a valid CSRF token
  protect_from_forgery with: :exception

  before_action :check_for_login_or_unauthorized!

  FORWARDED_RESPONSE_HEADERS = %w[Content-Type].freeze
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 300

  def forward
    path = params[:path].to_s
    return head :forbidden unless SequencescapeProxyPolicy.allowed?(request.request_method, path)

    response = upstream_request(path)
    render body: response.body,
           status: response.status,
           content_type: response.headers['Content-Type'] || 'application/vnd.api+json'
  rescue Faraday::TimeoutError
    head :gateway_timeout
  rescue Faraday::Error
    head :bad_gateway
  end

  private

  def check_for_login_or_unauthorized!
    head :unauthorized unless request.get? || logged_in?
  end

  def upstream_request(path)
    target = request.query_string.present? ? "#{path}?#{request.query_string}" : path
    body = request.get? ? nil : request.raw_post

    connection.run_request(request.request_method.downcase.to_sym, target, body, upstream_headers)
  end

  # Only content headers are passed on. The client's cookies, CSRF token and any
  # attempt to supply its own API key are dropped.
  def upstream_headers
    {
      'Accept' => request.headers['Accept'].presence || 'application/vnd.api+json',
      'Content-Type' => request.content_type.presence || 'application/vnd.api+json',
      'X-Sequencescape-Client-Id' => api_options.authorisation
    }
  end

  def connection
    Faraday.new(url: api_options.url, request: { open_timeout: OPEN_TIMEOUT, timeout: READ_TIMEOUT })
  end

  def api_options
    Limber::Application.config.api.v2.connection_options
  end
end
