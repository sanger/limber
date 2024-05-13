# frozen_string_literal: true

# Represents a Study in Limber via the Sequencescape API
class Sequencescape::Api::V2::Study < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasPolyMetadata

  # Returns the PolyMetadatum object with a matching key from poly_metadata
  # of this Study.
  #
  # @param key [String] the key of the PolyMetadatum to find
  # @return [PolyMetadatum, nil] the found PolyMetadatum object, or nil if no match is found
  def poly_metadatum_by_key(key)
    poly_metadata.find { |pm| pm.key == key }
  end
end
