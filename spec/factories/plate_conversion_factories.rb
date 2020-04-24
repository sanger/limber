# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # Generate a V1 API PlateConversion with minimal data
  factory :plate_conversion, class: Sequencescape::PlateConversion, traits: [:api_object] do
    json_root { 'plate_conversion' }

    with_belongs_to_associations 'target', 'purpose'
  end
end
