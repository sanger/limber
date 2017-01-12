# frozen_string_literal: true
FactoryGirl.define do
  factory :custom_metadatum_collection, class: Sequencescape::CustomMetadatumCollection, traits: [:api_object] do
    json_root 'custom_metadatum_collection'
  end
end