# frozen_string_literal: true

FactoryBot.define do
  # API v2 receptacle
  factory :v2_receptacle, class: Sequencescape::Api::V2::Receptacle do
    skip_create
    sequence(:id, &:to_s)
    uuid

    requests_as_source { [] }

    transient { qc_results { [] } }

    after(:build) do |receptacle, evaluator|
      receptacle._cached_relationship(:qc_results) { evaluator.qc_results || [] }
      receptacle._cached_relationship(:requests_as_source) { evaluator.requests_as_source || [] }
    end
  end
end
