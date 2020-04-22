# frozen_string_literal: true

FactoryBot.define do
  # Construct a Pipeline
  # Use create to automatically push it onto the pipelines array
  # build just returns the pipeline object
  factory :pipeline do
    to_create do |instance, evaluator|
      evaluator.pipeline_list << instance
    end

    transient do
      # Override the pipelines list if you wish to use a custom one
      # for testing
      pipeline_list { Settings.pipelines }
    end

    sequence(:name) { |i| "Pipleine #{i}" }
    filters { {} }
    relationships { {} }
    library_pass { nil }
  end
end
