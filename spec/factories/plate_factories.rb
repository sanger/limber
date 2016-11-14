require 'pry'

FactoryGirl.define do
  factory :plate, class: Limber::Plate, traits: [:api_object] do
     skip_create
     # plate_purpose
     json_root 'plate'
     
     state 'pending'
  end
end
