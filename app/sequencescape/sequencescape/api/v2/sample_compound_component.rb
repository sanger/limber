# frozen_string_literal: true

# Represents a sample in Limber via the Sequencescape API
class Sequencescape::Api::V2::SampleCompoundComponent < Sequencescape::Api::V2::Base
    has_one :asset, class_name: 'Sequencescape::Api::V2::Well'
    has_one :target_asset, class_name: 'Sequencescape::Api::V2::Well'

    #has_many :downstream_tubes, class_name: 'Sequencescape::Api::V2::Tube'

    has_one :compound_sample, class_name: 'Sequencescape::Api::V2::Sample'
    has_many :component_samples, class_name: 'Sequencescape::Api::V2::Sample'
end
  