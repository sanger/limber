# frozen_string_literal: true

# Represents a poly metadatum in Limber via the Sequencescape v2 API
class Sequencescape::Api::V2::PolyMetadatum < Sequencescape::Api::V2::Base
  # TODO: is this correct? integer? metadatable_id?
  property :metadatable, type: :id

  property :key, type: :string
  property :value, type: :string

  # TODO: needed?
  property :created_at, type: :time
  property :updated_at, type: :time
end
