# frozen_string_literal: true

# Represents a sample in Limber via the Sequencescape API
class Sequencescape::Api::V2::Sample < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasRequests
  has_one :sample_metadata, class_name: 'Sequencescape::Api::V2::SampleMetadata'
  has_many :component_samples, class_name: 'Sequencescape::Api::V2::Sample'
end
