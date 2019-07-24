# frozen_string_literal: true

FactoryBot.define do
  factory :user, class: Sequencescape::Api::V2::User do
    skip_create
    id { '1234' }
    uuid { SecureRandom.uuid }
    login { 'usr1' }
    email { 'example@example.com' }
    first_name { 'Jane' }
    last_name { 'Doe' }
  end

  factory :v1_user, class: Sequencescape::User, traits: [:api_object] do
    json_root { 'user' }
    login { 'usr1' }
    email { 'example@example.com' }
    first_name { 'Jane' }
    last_name { 'Doe' }
    swipecard_code? { true }
  end
end
