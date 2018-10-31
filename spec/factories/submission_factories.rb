# frozen_string_literal: true

FactoryBot.define do
  factory :submission, class: Sequencescape::Submission, traits: [:api_object] do
    json_root 'submission'
    named_actions %w[submit]
    orders []
    state 'building'
  end

  factory :v2_submission,  class: Sequencescape::Api::V2::Submission, traits: [:uuid] do
    to_create { |instance, _evaluator| instance.mark_as_persisted! }
  end
end
