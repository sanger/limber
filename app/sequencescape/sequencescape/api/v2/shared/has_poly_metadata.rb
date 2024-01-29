# frozen_string_literal: true

# Module for defining shared concerns that can be included in v2 classes to access
# resources via the Sequencescape v2 API
module Sequencescape::Api::V2::Shared
  # Represents a shared concern for poly metadatum
  module HasPolyMetadata
    extend ActiveSupport::Concern

    included { has_many :poly_metadata, class_name: 'Sequencescape::Api::V2::PolyMetadatum', as: :metadatable }
  end
end
