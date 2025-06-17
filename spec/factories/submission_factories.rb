# frozen_string_literal: true

FactoryBot.define do
  # API V2 submission. Pretty much just used for grouping requests via submission uuid
  factory :v2_submission, class: Sequencescape::Api::V2::Submission, traits: [:uuid] do
    sequence(:id, &:to_s)
    state { 'ready' }
    created_at { Time.current.to_s }
    updated_at { Time.current.to_s }

    to_create do |instance, _evaluator|
      # JSON API client resources are not persisted in the database, but we need Limber to treat them as if they are.
      # This ensures the `url_for` method will use their UUIDs in URLs via the `to_param` method on the resource.
      # Otherwise it just redirects to the root URL for the resource type.
      instance.mark_as_persisted!
    end
  end
end
