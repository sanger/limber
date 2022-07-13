# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :tube_rack, class: Sequencescape::Api::V2::TubeRack, traits: [:barcoded_v2] do
    skip_create

    initialize_with { Sequencescape::Api::V2::TubeRack.load(attributes) }

    transient do
      # Overide the purpose name
      purpose_name { 'example-purpose' }

      # Overive the purpose uuid
      purpose_uuid { 'example-purpose-uuid' }

      # The plate purpose
      purpose { create :v2_purpose, name: purpose_name, uuid: purpose_uuid }
      tubes { {} }

      racked_tubes do
        tubes.map { |coordinate, tube| create :racked_tube, coordinate: coordinate, tube: tube, tube_rack: instance }
      end
    end

    id
    uuid
    number_of_rows { 8 }
    number_of_columns { 12 }
    size { number_of_rows * number_of_columns }
    name { 'Example' }
    created_at { '2017-06-29T09:31:59.000+01:00' }
    updated_at { '2017-06-29T09:31:59.000+01:00' }

    after(:build) do |tube_rack, evaluator|
      Sequencescape::Api::V2::TubeRack.associations.each do |association|
        tube_rack._cached_relationship(association.attr_name) { evaluator.send(association.attr_name) }
      end
    end
  end

  factory :racked_tube, class: Sequencescape::Api::V2::RackedTube do
    skip_create

    initialize_with { Sequencescape::Api::V2::RackedTube.load(attributes) }

    id
    coordinate { 'A1' }

    transient do
      tube_rack { create :tube_rack }
      tube { create :v2_tube }
    end

    after(:build) do |racked_tube, evaluator|
      Sequencescape::Api::V2::RackedTube.associations.each do |association|
        racked_tube._cached_relationship(association.attr_name) { evaluator.send(association.attr_name) }
      end
    end
  end
end
