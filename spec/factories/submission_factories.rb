# frozen_string_literal: true

FactoryBot.define do
  # API V2 submission. Pretty much just used for grouping requests via submission uuid
  factory :submission, class: Sequencescape::Api::V2::Submission, traits: [:uuid] do
    transient do
      orders { [] }
    end

    sequence(:id, &:to_s)
    state { 'ready' }
    created_at { Time.current.to_s }
    updated_at { Time.current.to_s }

    after(:build) do |submission, evaluator|
      submission._cached_relationship(:orders) { evaluator.orders } if evaluator.orders.present?
    end

    to_create do |instance, _evaluator|
      # JSON API client resources are not persisted in the database, but we need Limber to treat them as if they are.
      # This ensures the `url_for` method will use their UUIDs in URLs via the `to_param` method on the resource.
      # Otherwise it just redirects to the root URL for the resource type.
      instance.mark_as_persisted!
    end
  end

  factory :order, class: Sequencescape::Api::V2::Order, traits: [:uuid] do
    sequence(:id, &:to_s)
    created_at { Time.current.to_s }
    updated_at { Time.current.to_s }

    to_create do |instance, _evaluator|
      instance.mark_as_persisted!
    end
  end
end
