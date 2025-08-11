# frozen_string_literal: true

FactoryBot.define do
  # API V2 study
  factory :study, class: Sequencescape::Api::V2::Study do
    skip_create

    id
    uuid

    name { 'Test Study' }

    factory :study_with_poly_metadata do
      transient { poly_metadata { [] } }

      after(:build) do |study, evaluator|
        # initialise the poly_metadata array
        study.poly_metadata = []

        # add each polymetadatum to the study
        evaluator.poly_metadata.each do |pm|
          # set the relationship between the polymetadatum and the study
          pm.relationships.metadatable = study

          # link the polymetadatum to the study
          study.poly_metadata.push(pm)
        end
      end
    end
  end
end
