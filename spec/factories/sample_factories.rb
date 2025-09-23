# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # API V2 sample
  factory :v2_sample, class: Sequencescape::Api::V2::Sample do
    skip_create

    uuid

    sequence(:sanger_sample_id) { |i| "sample #{i}" }
    sequence(:name) { |i| "sample_name #{i}" }
    sample_metadata { create(:v2_sample_metadata) }
    control { false }
    control_type { nil }
    sample_manifest { create(:v2_sample_manifest) }

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) { |sample, evaluator| sample._cached_relationship(:sample_metadata) { evaluator.sample_metadata } }
  end

  factory :v2_sample_metadata, class: Sequencescape::Api::V2::SampleMetadata do
    skip_create
    sequence(:supplier_name) { |i| "supplier name #{i}" }
    sample_common_name { 'Homo sapiens' }
    collected_by { 'Sanger' }
    cohort { 'Cohort' }
    sample_description { 'Description' }

    trait :with_donor do
      sequence(:donor_id) { |i| "donor#{i}" }
    end
  end

  factory :v2_sample_metadata_for_mbrave, class: Sequencescape::Api::V2::SampleMetadata do
    skip_create
    sequence(:cohort) { |i| "cohort #{i}" }
    sequence(:sample_description) { |i| "sample description #{i}" }
    sequence(:supplier_name) { |i| "supplier name #{i}" }
    sample_common_name { 'Homo sapiens' }
    collected_by { 'Sanger' }
  end

  factory :v2_sample_manifest, class: Sequencescape::Api::V2::SampleManifest do
    skip_create
    supplier_name { 'supplier1' }
  end
end
