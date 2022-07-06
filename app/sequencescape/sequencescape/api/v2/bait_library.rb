# frozen_string_literal: true

# Represents a bait library in Limber via the Sequencescape API
class Sequencescape::Api::V2::BaitLibrary < Sequencescape::Api::V2::Base
  def self.find_by(options)
    Sequencescape::Api::V2::BaitLibrary.find(options).first
  end
end