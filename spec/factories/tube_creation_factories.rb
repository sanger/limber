# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # Result of APIv1 tube creation
  factory :tube_creation, class: Sequencescape::TubeCreation, traits: [:api_object] do
    json_root { 'tube_creation' }

    with_belongs_to_associations 'parent', 'child_purpose', 'child'
  end

  # APIv1 result of a specific_tube_creation which allows the generation of
  # one or more tubes of specific purposes
  factory :specific_tube_creation, class: Sequencescape::SpecificTubeCreation, traits: [:api_object] do
    json_root { 'specific_tube_creation' }
    with_belongs_to_associations 'parent', 'user'
    with_has_many_associations 'children', 'child_purposes'
  end
end
