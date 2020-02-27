# frozen_string_literal: true

class Sequencescape::Api::V2::Sample < Sequencescape::Api::V2::Base
  has_one :sample_metadata, class_name: 'Sequencescape::Api::V2::SampleMetadata'
end
