# frozen_string_literal: true

FactoryBot.define do
  # API V2 study
  factory :v2_study, class: Sequencescape::Api::V2::Study do
    skip_create

    sequence(:sanger_sample_id) { |i| "sample #{i}" }
    name { 'Test Study' }

    uuid { SecureRandom.uuid }
  end
end