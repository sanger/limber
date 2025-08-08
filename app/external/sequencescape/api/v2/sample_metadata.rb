# frozen_string_literal: true

# Represents a sample metadatum in Limber via the Sequencescape API
class Sequencescape::Api::V2::SampleMetadata < Sequencescape::Api::V2::Base
  has_one :sample, class_name: 'Sequencescape::Api::V2::Sample'

  DEFAULT_INCLUDES = [].freeze

  def self.find_by(options, includes: DEFAULT_INCLUDES)
    Sequencescape::Api::V2::SampleMetadata.includes(*includes).find(**options).first
  end
end
