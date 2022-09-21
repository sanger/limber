# frozen_string_literal: true

# Represents a sample in Limber via the Sequencescape API
class Sequencescape::Api::V2::SubmissionTemplate < Sequencescape::Api::V2::Base
    has_many :orders, class_name: 'Sequencescape::Api::V2::Order'
  
    DEFAULT_INCLUDES = [].freeze
  
    def self.find_by(options, includes: DEFAULT_INCLUDES)
      Sequencescape::Api::V2::SubmissionTemplate.includes(*includes).find(options).first
    end
  
  end
  