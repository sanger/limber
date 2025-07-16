# frozen_string_literal: true

FactoryBot.define do
  # API V2 PolyMetadatum
  factory :poly_metadatum, class: Sequencescape::Api::V2::PolyMetadatum do
    skip_create

    sequence(:key) { |n| "some_key_#{n}" }
    sequence(:value) { |n| "some_value_#{n}" }

    transient { metadatable { create :library_request } }

    after(:build) do |poly_metadatum, evaluator|
      poly_metadatum.relationships.metadatable = {
        'links' => {},
        'data' => {
          'type' => 'Request',
          'id' => evaluator.metadatable.id
        }
      }
    end
  end
end
