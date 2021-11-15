# frozen_string_literal: true

# Represents a sample in Limber via the Sequencescape API
class Sequencescape::Api::V2::Sample < Sequencescape::Api::V2::Base
  has_one :sample_metadata, class_name: 'Sequencescape::Api::V2::SampleMetadata'

  DEFAULT_INCLUDES = [].freeze

  def self.find_by(options, includes: DEFAULT_INCLUDES)
    Sequencescape::Api::V2::Sample.includes(*includes).find(options).first
  end
end
