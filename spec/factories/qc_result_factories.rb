# frozen_string_literal: true

FactoryBot.define do
  factory :qc_result, class: Sequencescape::Api::V2::QcResult do
    key 'concentration'
    value '1.5'
    units 'nM'
    created_at { Time.current }

    skip_create
  end
end
