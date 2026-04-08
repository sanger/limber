# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # Generates an api v2 tube with the Sequencescape::Api::V2::Asset class
  # This is required to mimic the behaviour of the API gem when loading some
  # polymorphic resources
  factory :asset_tube, class: Sequencescape::Api::V2::Asset, traits: [:barcoded] do
    skip_create
    uuid
    name { 'My tube' }
    type { 'tubes' }
    state { 'passed' }

    purpose_name { 'example-purpose' }
    purpose_uuid { 'example-purpose-uuid' }
    purpose { create :purpose, name: purpose_name, uuid: purpose_uuid }

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) { |asset, evaluator| asset._cached_relationship(:purpose) { evaluator.purpose } }
  end
end
