# frozen_string_literal: true

FactoryBot.define do
  # API v2 user
  factory :user, class: Sequencescape::Api::V2::User do
    skip_create

    uuid

    id { '1234' }
    login { 'usr1' }
    email { 'example@example.com' }
    first_name { 'Jane' }
    last_name { 'Doe' }
  end
end
