# frozen_string_literal: true

# Represents a poly metadatum in Limber via the Sequencescape v2 API
class Sequencescape::Api::V2::PolyMetadatum < Sequencescape::Api::V2::Base
  belongs_to :metadatable, polymorphic: true, shallow_path: true

  property :key, type: :string
  property :value, type: :string

  property :created_at, type: :time
  property :updated_at, type: :time
end
