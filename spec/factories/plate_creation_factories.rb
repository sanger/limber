require_relative '../support/factory_girl_extensions'

FactoryGirl.define do
  factory :plate_creation, class: Sequencescape::PlateCreation, traits: [:api_object] do
    json_root 'plate_creation'

    with_belongs_to_associations 'parent', 'child_purpose', 'child'

  end
end
