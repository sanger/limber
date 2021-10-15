# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # API V2 sample
  factory :v2_sample, class: Sequencescape::Api::V2::Sample do
    skip_create

    sequence(:id, &:to_s)

    transient do
      component_samples_count { 0 }
    end

    sequence(:sanger_sample_id) { |i| "sample #{i}" }
    sample_metadata { create(:v2_sample_metadata) }
    component_samples { create_list :v2_sample, component_samples_count }
    control { false }
    control_type { nil }

    after(:build) do |sample, evaluator|
      sample._cached_relationship(:sample_metadata) { evaluator.sample_metadata }
      sample._cached_relationship(:component_samples) { evaluator.component_samples }
    end
  end

  # API V1 sample
  factory :sample, class: Sequencescape::Sample, traits: [:api_object] do
    transient do
      name { 'sample' }
      sample_id { 'SAM1' }
    end

    json_root { 'sample' }

    reference { { 'genome' => 'reference_genome' } }
    sanger    { { 'name' => name, 'sample_id' => sample_id } }
  end

  factory :v2_sample_metadata, class: Sequencescape::Api::V2::SampleMetadata do
    skip_create
    sequence(:supplier_name) { |i| "supplier name #{i}" }
    supplier { 'supplier1' }
  end
end
