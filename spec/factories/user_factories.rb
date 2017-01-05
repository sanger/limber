# frozen_string_literal: true
FactoryGirl.define do
  factory :user, class: Sequencescape::User, traits: [:api_object] do
    json_root 'user'
    login 'usr1'
    email 'example@example.com'
    first_name 'Jane'
    last_name 'Doe'
    swipecard_code? true
  end
end
