# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :tube_rack, class: Sequencescape::Api::V2::TubeRack, traits: [:barcoded] do
    skip_create

    initialize_with { Sequencescape::Api::V2::TubeRack.load(attributes) }

    transient do
      # Overide the purpose name
      purpose_name { 'example-purpose' }

      # Overide the purpose uuid
      purpose_uuid { 'example-purpose-uuid' }

      # The tube rack purpose
      purpose { create :tube_rack_purpose, name: purpose_name, uuid: purpose_uuid }
      tubes { {} }

      # The parent assets
      parents { [] }

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

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) do |tube_rack, evaluator|
      Sequencescape::Api::V2::TubeRack.associations.each do |association|
        tube_rack._cached_relationship(association.attr_name) { evaluator.send(association.attr_name) }
      end

      tube_rack._cached_relationship(:parents) { evaluator.parents }
    end
  end

  factory :racked_tube, class: Sequencescape::Api::V2::RackedTube do
    # skips normal create and uses the after(:build) block to set up the relationships
    skip_create

    initialize_with { Sequencescape::Api::V2::RackedTube.load(attributes) }

    id
    coordinate { 'A1' }

    transient do
      tube_rack { create :tube_rack }
      tube { create :tube, racked_tube: instance }
    end

    after(:build) do |racked_tube, evaluator|
      Sequencescape::Api::V2::RackedTube.associations.each do |association|
        racked_tube._cached_relationship(association.attr_name) { evaluator.send(association.attr_name) }
      end

      racked_tube._cached_relationship(:tube_rack) { evaluator.tube_rack }
      racked_tube._cached_relationship(:tube) { evaluator.tube }
    end
  end
end
