# frozen_string_literal: true

class Sequencescape::Api::V2::Base < JsonApiClient::Resource # rubocop:todo Style/Documentation
  class_attribute :plate, :tube
  # set the api base url in an abstract base class
  self.site = Limber::Application.config.api.v2.connection_options.url
  self.plate = false
  self.tube = false
end
