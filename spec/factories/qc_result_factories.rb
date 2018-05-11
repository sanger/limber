FactoryBot.define do
  factory :qc_result, class: Sequencescape::Api::V2::QcResult do
    key 'concentration'
    value '1'
    created_at { DateTime.current }

    skip_create
  end
end
