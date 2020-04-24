# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # Generate a V1 API PlateCreation with minimal data
  factory :plate_creation, class: Sequencescape::PlateCreation, traits: [:api_object] do
    json_root { 'plate_creation' }

    with_belongs_to_associations 'parent', 'child_purpose', 'child'
  end
end
