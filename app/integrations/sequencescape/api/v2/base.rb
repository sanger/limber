# frozen_string_literal: true

class Sequencescape::Api::V2::Base < JsonApiClient::Resource # rubocop:todo Style/Documentation
  class_attribute :plate, :tube, :tube_rack

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
