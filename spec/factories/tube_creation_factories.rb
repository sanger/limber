# frozen_string_literal: true
require_relative '../support/factory_girl_extensions'

FactoryGirl.define do
  factory :tube_creation, class: Sequencescape::TubeCreation, traits: [:api_object] do
    json_root 'tube_creation'

    with_belongs_to_associations 'parent', 'child_purpose', 'child'
  end

  factory :specific_tube_creation, class: Sequencescape::SpecificTubeCreation, traits: [:api_object] do
    json_root 'specific_tube_creation'
    with_belongs_to_associations 'parent', 'user'
    with_has_many_associations 'children', 'child_purposes'
  end
end
