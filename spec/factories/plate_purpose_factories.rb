# frozen_string_literal: true

FactoryBot.define do
  # Basic v2 Plate Purpose
  factory :purpose, class: Sequencescape::Api::V2::Purpose, traits: [:barcoded] do
    skip_create
    sequence(:name) { |n| "Limber Example Purpose #{n}" }
    uuid { 'example-purpose-uuid' }
  end

  # Basic v2 Tube Rack Purpose
  factory :tube_rack_purpose, class: Sequencescape::Api::V2::TubeRackPurpose, traits: [:barcoded] do
    skip_create
    sequence(:name) { |n| "Limber Example TubeRackPurpose #{n}" }
    uuid { 'example-tr-purpose-uuid' }
  end
end
