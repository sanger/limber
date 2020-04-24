# frozen_string_literal: true

FactoryBot.define do
  # API V2 qc result with molarity data
  factory :qc_result, class: Sequencescape::Api::V2::QcResult do
    key { 'molarity' }
    value { '1.5' }
    units { 'nM' }
    created_at { Time.current }

    skip_create

    # API V2 qc result with concentration data
    factory :qc_result_concentration do
      key { 'concentration' }
      units { 'ng/ul' }
    end
  end
end
