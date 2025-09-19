# frozen_string_literal: true

FactoryBot.define do
  # Generate a V2 api metadata collection
  factory :custom_metadatum_collection, class: Sequencescape::Api::V2::CustomMetadatumCollection do
    initialize_with { Sequencescape::Api::V2::CustomMetadatumCollection.load(attributes) }
    skip_create
    uuid
    metadata { { metadata_1: 'metadata_1', metadata_2: 'metadata_2' } }
  end
end
