# frozen_string_literal: true

# Represents a bait library in Limber via the Sequencescape API
class Sequencescape::Api::V2::BaitLibrary < Sequencescape::Api::V2::Base
  DEFAULT_INCLUDES = [].freeze

  def self.find_by(options, includes: DEFAULT_INCLUDES)
    Sequencescape::Api::V2::BaitLibrary.includes(*includes).find(options).first
  end
end