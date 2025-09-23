# frozen_string_literal: true

FactoryBot.define do
  # Basic v2 Plate Purpose
  factory :v2_purpose, class: Sequencescape::Api::V2::Purpose, traits: [:barcoded_v2] do
    skip_create
    sequence(:name) { |n| "Limber Example Purpose #{n}" }
    uuid { 'example-purpose-uuid' }
  end

  # Basic v2 Tube Rack Purpose
  factory :v2_tube_rack_purpose, class: Sequencescape::Api::V2::TubeRackPurpose, traits: [:barcoded_v2] do
    skip_create
    sequence(:name) { |n| "Limber Example TubeRackPurpose #{n}" }
    uuid { 'example-tr-purpose-uuid' }
  end
end
