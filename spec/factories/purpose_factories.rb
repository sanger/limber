require 'pry'

FactoryGirl.define do
  factory :plate_purpose, class: Limber::PlatePurpose, traits: [:api_object] do
    name 'Limber Example Purpose'
  end
end
