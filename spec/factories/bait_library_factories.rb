# frozen_string_literal: true

FactoryBot.define do
  factory :bait_library, class: Sequencescape::Api::V2::BaitLibrary do
    skip_create

    name { 'My Hyb Panel' }
  end
end
