# frozen_string_literal: true

# Represents a request metadata in Limber via the Sequencescape API
class Sequencescape::Api::V2::RequestMetadata < Sequencescape::Api::V2::Base
  has_one :request, class_name: 'Sequencescape::Api::V2::Request'

  DEFAULT_INCLUDES = [].freeze

  def self.find_by(options, includes: DEFAULT_INCLUDES)
    Sequencescape::Api::V2::RequestMetadata.includes(*includes).find(**options).first
  end
end
