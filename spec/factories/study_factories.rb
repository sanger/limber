# frozen_string_literal: true

FactoryBot.define do
  # API V2 study
  factory :v2_study, class: Sequencescape::Api::V2::Study do
    skip_create

    name { 'Test Study' }

    uuid { SecureRandom.uuid }
  end
end
