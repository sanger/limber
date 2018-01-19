
# frozen_string_literal: true

FactoryBot.define do
  factory :plate_purpose, class: Limber::PlatePurpose, traits: [:api_object] do
    name 'Limber Example Purpose'
    uuid 'example-purpose-uuid'
    json_root 'plate_purpose'
    with_has_many_associations 'plates', 'children'

    factory :stock_plate_purpose do
      name 'Limber Cherrypicked'
      uuid 'stock-plate-purpose-uuid'
    end
  end

  factory :tube_purpose, class: Sequencescape::TubePurpose, traits: [:api_object] do
    name 'Limber Example Purpose'
    json_root 'tube_purpose'
    with_has_many_associations 'tubes', 'children'
  end

  factory :plate_purpose_collection, class: Sequencescape::Api::Associations::HasMany::AssociationProxy, traits: [:api_object] do
    size 2

    transient do
      json_root nil
      resource_actions %w[read first last]
      purpose_uuid { SecureRandom.uuid }
      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}#{purpose_uuid}/children/1" }
      uuid nil
    end

    plate_purposes do
      Array.new(size) { |i| associated(:plate_purpose, name: 'Child Purpose ' + i.to_s, uuid: 'child-purpose-' + i.to_s) }
    end
  end
end
