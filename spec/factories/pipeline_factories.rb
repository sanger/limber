# frozen_string_literal: true

FactoryBot.define do
  factory :pipeline do
    to_create do |instance, evaluator|
      evaluator.pipeline_list << instance
    end

    transient do
      pipeline_list { Settings.pipelines }
    end

    sequence(:name) { |i| "Pipleine #{i}" }
    filters { {} }
    relationships { {} }
    library_pass { nil }
  end
end
