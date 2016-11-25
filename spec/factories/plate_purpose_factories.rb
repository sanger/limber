
FactoryGirl.define do
  factory :plate_purpose, class: Limber::PlatePurpose, traits: [:api_object] do
    name 'Limber Example Purpose'
    json_root 'plate_purpose'
    with_has_many_associations 'plates', 'children'
  end
end
