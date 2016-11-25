# frozen_string_literal: true
require './lib/well_helpers'
require_relative '../support/factory_girl_extensions'

FactoryGirl.define do
  factory :well, class: Sequencescape::Well, traits: [:api_object] do
    transient do
      sample_count 1
    end

    json_root 'well'
    state 'pending'
    location 'A1'

    aliquots do
      Array.new(sample_count) do |i|
        associated(:aliquot, sample_name: "sample_#{location}_#{i}", sample_id: "SAM#{location}#{i}", sample_uuid: "example-sample-uuid-#{i}")
      end
    end
  end

  factory :well_collection, class: Sequencescape::Api::Associations::HasMany::AssociationProxy, traits: [:api_object] do
    size 96

    transient do
      locations { WellHelpers.column_order.slice(0, size) }
      json_root nil
      resource_actions %w(read first last)
      plate_uuid   { SecureRandom.uuid }
      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}#{plate_uuid}/wells/1" }
      uuid nil
    end

    wells do
      locations.each_with_index.map do |location, i|
        associated(:well, location: location, uuid: "example-well-uuid-#{i}")
      end
    end
  end

  factory :aliquot, class: Sequencescape::Behaviour::Receptacle::Aliquot do
    bait_library nil
    insert_size { {} }
    tag { {} }

    sample { associated(:sample, name: sample_name, sample_id: sample_id, uuid: sample_uuid) }

    transient do
      sample_name 'sample'
      sample_id   'SAM0'
      sample_uuid 'example-sample-uuid-0'
    end
  end

  factory :sample, class: Sequencescape::Sample, traits: [:api_object] do
    transient do
      name 'sample'
      sample_id   'SAM1'
    end

    json_root 'sample'

    reference { { 'genome' => 'reference_genome' } }
    sanger    { { 'name' => name, 'sample_id' => sample_id } }
  end
end
