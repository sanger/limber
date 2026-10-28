# frozen_string_literal: true

FactoryBot.define do
  # An Ultima application with its UGA and UGB primers
  factory :ultima_application,
          class: Sequencescape::Api::V2::UltimaApplication do
    skip_create

    sequence(:name) { |index| "Ultima application #{index}" }
    description { 'An Ultima application' }
    uga_primer { create :ultima_primer }
    ugb_primer { create :ultima_primer }

    # See the README.md for an explanation under "FactoryBot is not mocking my
    # related resources correctly"
    after(:build) do |application, evaluator|
      application._cached_relationship(:uga_primer) { evaluator.uga_primer }
      application._cached_relationship(:ugb_primer) { evaluator.ugb_primer }
    end
  end

  # A UGA or UGB primer of an Ultima application
  factory :ultima_primer, class: Sequencescape::Api::V2::UltimaPrimer do
    skip_create

    sequence(:name) { |index| "UG-primer-#{index}" }
  end
end
