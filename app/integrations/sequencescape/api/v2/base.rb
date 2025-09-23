# frozen_string_literal: true

class Sequencescape::Api::V2::Base < JsonApiClient::Resource # rubocop:todo Style/Documentation
  class_attribute :plate, :tube, :tube_rack

  # Implement a find method that raises a ResourceNotFound error if no record is found.
  # Calls the standard find method, and raises if the result is nil.
  # Should this be rolled into the JsonApiClient gem?
  # @raise [JsonApiClient::Errors::NotFound] if no record is found
  def self.find!(*)
    record = find(*)
    raise JsonApiClient::Errors::NotFound, 'Resource not found' if record.empty?

    record
  end

  # Adjusts the parameters used for pagination. We create a custom
  # class to avoid mutating the global JsonApiClient::Paginating::Paginator object
  class SequencescapePaginator < JsonApiClient::Paginating::NestedParamPaginator
    self.page_param = 'number'
    self.per_page_param = 'size'
  end

  # set the api base url in an abstract base class
  self.site = Limber::Application.config.api.v2.connection_options.url
  connection.faraday.headers['X-Sequencescape-Client-Id'] = Limber::Application
    .config
    .api
    .v2
    .connection_options
    .authorisation
  self.plate = false
  self.tube = false
  self.tube_rack = false
  self.paginator = SequencescapePaginator
end
