# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # API V2 sample
  factory :v2_sample, class: Sequencescape::Api::V2::Sample do
    skip_create

    sequence(:sanger_sample_id) { |i| "sample #{i}" }
    sample_metadata { create(:v2_sample_metadata) }
    control { false }
    control_type { nil }
    sample_manifest { create(:v2_sample_manifest) }
    uuid { SecureRandom.uuid }

    after(:build) { |sample, evaluator| sample._cached_relationship(:sample_metadata) { evaluator.sample_metadata } }
  end

  # API V1 sample
  factory :sample, class: Sequencescape::Sample, traits: [:api_object] do
    transient do
      name { 'sample' }
      sample_id { 'SAM1' }
    end

    json_root { 'sample' }

    reference { { 'genome' => 'reference_genome' } }
    sanger { { 'name' => name, 'sample_id' => sample_id } }
  end

  factory :v2_sample_metadata, class: Sequencescape::Api::V2::SampleMetadata do
    skip_create
    sequence(:supplier_name) { |i| "supplier name #{i}" }
    sample_common_name { 'Homo sapiens' }
    collected_by { 'Sanger' }
    cohort { 'Cohort' }
    sample_description { 'Description' }
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
