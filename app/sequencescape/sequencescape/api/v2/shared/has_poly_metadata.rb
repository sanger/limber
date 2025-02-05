# frozen_string_literal: true

# Module for defining shared concerns that can be included in v2 classes to access
# resources via the Sequencescape v2 API
module Sequencescape::Api::V2::Shared
  # Represents a shared concern for poly metadatum
  module HasPolyMetadata
    extend ActiveSupport::Concern

    included { has_many :poly_metadata, class_name: 'Sequencescape::Api::V2::PolyMetadatum', as: :metadatable }

    # Returns the first PolyMetadatum object from poly_metadata for the
    # specified key.
    #
    # @param key [String] the key of the PolyMetadatum to find
    # @return [PolyMetadatum, nil] the found PolyMetadatum object, or nil if no match is found
    def poly_metadatum_by_key(key)
      # if no poly_metadata exist for this model instance, or no key value is passed, return nil
      return nil if poly_metadata.blank? || key.blank?

      # Return the first PolyMetadatum object with a matching key
      poly_metadata.detect { |pm| pm.key == key }
    end
  end
end
