# frozen_string_literal: true

FactoryBot.define do
  factory :tag_layout_template, class: Sequencescape::Api::V2::TagLayoutTemplate do
    skip_create

    uuid

    sequence(:name) { |index| "TagLayoutTemplate#{index}" }

    direction { 'column' }
    walking_by { 'wells of plate' }
    transient do
      tag_group { create :tag_group_with_tags }
      tag2_group { nil }
    end

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) do |tag_layout_template, evaluator|
      tag_layout_template._cached_relationship(:tag_group) { evaluator.tag_group } if evaluator.tag_group
      tag_layout_template._cached_relationship(:tag2_group) { evaluator.tag2_group } if evaluator.tag2_group
    end

    factory :tag_layout_template_by_row do
      direction { 'row' }
    end

    factory :tag_layout_template_by_inverse_column do
      direction { 'inverse_column' }
    end

    factory :tag_layout_template_by_inverse_row do
      direction { 'inverse_row' }
    end

    factory :tag_layout_template_by_quadrant do
      walking_by { 'quadrants' }
      direction { 'column then row' }

      factory :tag_layout_template_by_quadrant_in_columns do
        direction { 'column' }
      end

      factory :tag_layout_template_by_quadrant_in_columns_then_columns do
        direction { 'column then column' }
      end
    end

    factory :tag_layout_template_combinatorial_by_row do
      walking_by { 'combinatorial sequential' }
      direction { 'combinatorial by row' }
    end

    factory :dual_index_tag_layout_template do
      transient { tag2_group { create :tag_group_with_tags } }
    end
  end
end
