# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :v2_asset_tube, class: Sequencescape::Api::V2::Asset, traits: [:barcoded_v2] do
    # Generates an api v2 tube with the Sequencescape::Api::V2::Asset class
    # This is required to mimic the behaviour of the API gem when loading some
    # polymorphic resources
    skip_create
    uuid { SecureRandom.uuid }
    name { 'My tube' }
    type { 'tubes' }
    state { 'passed' }

    purpose_name { 'example-purpose' }
    purpose_uuid { 'example-purpose-uuid' }
    purpose { create :v2_purpose, name: purpose_name, uuid: purpose_uuid }

    # Mock the relationships. Should probably handle this all a bit differently
    after(:build) do |asset, evaluator|
      RSpec::Mocks.allow_message(asset, :purpose).and_return(evaluator.purpose)
    end
  end
end
