
# frozen_string_literal: true

FactoryGirl.define do
  factory :submission, class: Sequencescape::Submission, traits: [:api_object] do
    json_root 'submission'
    named_actions %w[submit]
    orders []
    state 'building'
  end
end
