# frozen_string_literal: true

FactoryBot.define do
  # Builds a config hash as though loaded from config/purposes/*.yml
  # Using create automatically registers it in the Settings object
  factory :bait_library, class: Sequencescape::Api::V2::BaitLibrary do
    skip_create

    name { 'My Hyb Panel' }
  end
end
