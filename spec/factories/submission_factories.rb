# frozen_string_literal: true

FactoryBot.define do
  # API V1 submission
  factory :submission, class: Sequencescape::Submission, traits: [:api_object] do
    json_root { 'submission' }
    named_actions { %w[submit] }
    orders { [] }
    state { 'building' }
  end

  # API V2 submission. Pretty much just used for grouping requests via submission uuid
  factory :v2_submission, class: Sequencescape::Api::V2::Submission, traits: [:uuid] do
    sequence(:id, &:to_s)
    state { 'ready' }
    created_at { Time.current.to_s }
    updated_at { Time.current.to_s }
    to_create { |instance, _evaluator| instance.mark_as_persisted! }
  end
end
