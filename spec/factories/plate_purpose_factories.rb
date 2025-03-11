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

  # Basic V1 Plate Purpose
  factory :plate_purpose, class: Sequencescape::PlatePurpose, traits: [:api_object] do
    name { 'Limber Example Purpose' }
    uuid { 'example-purpose-uuid' }
    json_root { 'plate_purpose' }
    with_has_many_associations 'plates', 'children'

    # Basic V1 Stock Plate Purpose
    factory :stock_plate_purpose do
      name { 'Limber Cherrypicked' }
      uuid { 'stock-plate-purpose-uuid' }
    end
  end

  # Basic V1 Tube Purpose
  factory :tube_purpose, class: Sequencescape::TubePurpose, traits: [:api_object] do
    name { 'Limber Example Purpose' }
    json_root { 'tube_purpose' }
    with_has_many_associations 'tubes', 'children'
  end

  # API V1 list of plate purposes as though from api.plate_purpose.all
  factory :plate_purpose_collection, class: Sequencescape::Api::PageOfResults, traits: [:api_object] do
    size { 2 }

    transient do
      json_root { nil }
      resource_actions { %w[read first last] }
      purpose_uuid { SecureRandom.uuid }

      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}#{purpose_uuid}/children/1" }
      uuid { nil }
    end

    plate_purposes do
      Array.new(size) { |i| associated(:plate_purpose, name: "Child Purpose #{i}", uuid: "child-purpose-#{i}") }
    end
  end
end
