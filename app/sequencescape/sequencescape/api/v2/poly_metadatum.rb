# frozen_string_literal: true

# Represents a poly metadatum in Limber via the Sequencescape v2 API
# NB. When using this, we find that if we set the metadatable in the
# initializer, the save fails as the metadatable is treated as an
# attribute and not a relationship.
# To use this we found we had to do these steps:
# 1. select the metadatable object instance (e.g. a request here) e.g.
#    r = Sequencescape::Api::V2::Request.find(1234).first
# 2. create the new poly metadatum instance, e.g.
#    pm1 = Sequencescape::Api::V2::PolyMetadatum.new(key: 'test_key', value: 'test_value')
# 3. then set the metadatable on the new poly metadatum, e.g.
#    pm1.relationships.metadatable = r
# 4. then finally save the poly metadatum to persist it, i.e.
#    pm1.save
class Sequencescape::Api::V2::PolyMetadatum < Sequencescape::Api::V2::Base
  has_one :metadatable, polymorphic: true, shallow_path: true

  property :key, type: :string
  property :value, type: :string

  property :created_at, type: :time
  property :updated_at, type: :time
end
