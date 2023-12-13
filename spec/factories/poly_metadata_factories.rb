# frozen_string_literal: true

FactoryBot.define do
  # API V2 PolyMetadatum
  factory :v2_poly_metadatum, class: Sequencescape::Api::V2::PolyMetadatum do
    skip_create

    metadatable factory: %i[v2_request]
    sequence(:key) { |n| "some_key_#{n}" }
    sequence(:value) { |n| "some_value_#{n}" }
  end
end
