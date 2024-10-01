# frozen_string_literal: true

FactoryBot.define do
  # Generate a V1 api metadata collection
  factory :v1_custom_metadatum_collection, class: Sequencescape::CustomMetadatumCollection, traits: [:api_object] do
    json_root { 'custom_metadatum_collection' }
    with_belongs_to_associations 'user', 'asset'
    metadata { { metadata_1: 'metadata_1', metadata_2: 'metadata_2' } }
    resource_actions { %w[read create update] }
  end

  # Generate a V2 api metadata collection
  factory :custom_metadatum_collection, class: Sequencescape::Api::V2::CustomMetadatumCollection do
    initialize_with { Sequencescape::Api::V2::CustomMetadatumCollection.load(attributes) }
    skip_create
    uuid
    metadata { { metadata_1: 'metadata_1', metadata_2: 'metadata_2' } }
  end
end
