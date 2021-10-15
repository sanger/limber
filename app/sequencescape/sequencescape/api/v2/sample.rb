# frozen_string_literal: true

# Represents a sample in Limber via the Sequencescape API
class Sequencescape::Api::V2::Sample < Sequencescape::Api::V2::Base
  has_many :component_samples
  has_one :sample_metadata, class_name: 'Sequencescape::Api::V2::SampleMetadata'

  #
  # Returns the total number of component samples associated with the aliquot.
  # If there are no component samples, returns 1, not 0, as we have just a single
  # standard sample instead
  #
  # @return [Integer] The number of samples/component samples within the aliquot
  #
  def component_samples_count
    component_samples.length.clamp(1..)
  end
end
