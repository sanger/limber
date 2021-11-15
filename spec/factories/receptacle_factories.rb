# frozen_string_literal: true

FactoryBot.define do
  # API v2 receptacle
  factory :v2_receptacle, class: Sequencescape::Api::V2::Receptacle do
    skip_create
    sequence(:id, &:to_s)
    uuid

    transient do
      qc_results { [] }
    end

    after(:build) do |receptacle, evaluator|
      receptacle._cached_relationship(:qc_results) { evaluator.qc_results || [] }
    end
  end
end
