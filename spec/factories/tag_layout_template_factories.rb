# frozen_string_literal: true

FactoryBot.define do
  factory :v2_tag_layout_template, class: Sequencescape::Api::V2::TagLayoutTemplate do
    skip_create

    uuid

    sequence(:name) { |index| "TagLayoutTemplate#{index}" }

    direction { 'column' }
    walking_by { 'wells of plate' }
    transient do
      tag_group { create :v2_tag_group_with_tags }
      tag2_group { nil }
    end

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) do |tag_layout_template, evaluator|
      tag_layout_template._cached_relationship(:tag_group) { evaluator.tag_group } if evaluator.tag_group
      tag_layout_template._cached_relationship(:tag2_group) { evaluator.tag2_group } if evaluator.tag2_group
    end

    factory :v2_dual_index_tag_layout_template do
      transient { tag2_group { create :v2_tag_group_with_tags } }
    end
  end
end
