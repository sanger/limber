# frozen_string_literal: true

# Represents a request type in Limber via the Sequencescape API
class Sequencescape::Api::V2::RequestType < Sequencescape::Api::V2::Base
  has_many :requests
end
