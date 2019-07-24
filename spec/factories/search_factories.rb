# frozen_string_literal: true

FactoryBot.define do
  factory :search, class: Sequencescape::Search, traits: [:api_object] do
    json_root { 'search' }
    name { 'Find something' }
    named_actions { %w[first last all] }

    factory :swipecard_search do
      name { 'Find user by swipecard code' }
    end
  end
end
