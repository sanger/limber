# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # API V2 sample
  factory :v2_sample, class: Sequencescape::Api::V2::Sample do
    skip_create
    sequence(:sanger_sample_id) { |i| "sample #{i}" }
    sample_metadata { create(:v2_sample_metadata) }

    after(:build) do |sample, evaluator|
      RSpec::Mocks.allow_message(sample, :sample_metadata).and_return(evaluator.sample_metadata)
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
  end
end
