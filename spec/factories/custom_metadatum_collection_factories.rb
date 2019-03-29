# frozen_string_literal: true

FactoryBot.define do
  factory :v1_custom_metadatum_collection, class: Sequencescape::CustomMetadatumCollection, traits: [:api_object] do
    json_root { 'custom_metadatum_collection' }
    with_belongs_to_associations 'user', 'asset'
    metadata { { metadata_1: 'metadata_1', metadata_2: 'metadata_2' } }
    resource_actions { %w[read create update] }
  end

  factory :custom_metadatum_collection, class: Sequencescape::Api::V2::CustomMetadatumCollection do
    initialize_with do
      Sequencescape::Api::V2::CustomMetadatumCollection.load(attributes)
    end
    skip_create
    metadata { { metadata_1: 'metadata_1', metadata_2: 'metadata_2' } }
  end
end
