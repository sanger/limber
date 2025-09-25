# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :labware, class: Sequencescape::Api::V2::Labware, traits: [:barcoded] do
    skip_create

    initialize_with { Sequencescape::Api::V2::Labware.load(attributes) }

    id
    uuid
    type { 'labware' }

    transient do
      purpose { nil }
      ancestors { [] }
    end

    factory(:labware_plate) { type { 'plates' } }
    factory(:labware_tube) { type { 'tubes' } }
    factory(:labware_tube_rack) { type { 'tube_racks' } }

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) do |labware, evaluator|
      labware._cached_relationship(:purpose) { evaluator.purpose } if evaluator.purpose
      labware._cached_relationship(:ancestors) { evaluator.ancestors } if evaluator.ancestors
    end

    factory(:labware_with_state_changes) do
      state_changes { create_list :state_change, 2, target_state: }

      after(:build) { |labware, evaluator| labware._cached_relationship(:state_changes) { evaluator.state_changes } }
    end
  end
end
