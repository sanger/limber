# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :labware, class: Sequencescape::Api::V2::Labware, traits: [:barcoded_v2] do
    skip_create

    initialize_with do
      Sequencescape::Api::V2::Labware.load(attributes)
    end

    id
    uuid
    type { 'labware' }

    factory(:labware_plate) { type { 'plates' } }
    factory(:labware_tube) { type { 'tubes' } }
  end
end
