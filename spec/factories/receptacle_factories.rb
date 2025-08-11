# frozen_string_literal: true

FactoryBot.define do
  # API v2 receptacle
  factory :receptacle, class: Sequencescape::Api::V2::Receptacle do
    skip_create
    sequence(:id, &:to_s)
    uuid

    requests_as_source { [] }
    aliquots { [] }

    transient { qc_results { [] } }

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) do |receptacle, evaluator|
      receptacle._cached_relationship(:qc_results) { evaluator.qc_results || [] }
      receptacle._cached_relationship(:requests_as_source) { evaluator.requests_as_source || [] }
      receptacle._cached_relationship(:aliquots) { evaluator.aliquots || [] }
    end
  end
end
