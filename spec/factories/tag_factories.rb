# frozen_string_literal: true

def generate_oligo
  bases = %w[A T C G]
  min_oligo_size = 6
  max_oligo_size = 10

  (min_oligo_size + rand(max_oligo_size)).times.to_a.map { bases[rand(bases.length)] }.join
end

FactoryBot.define do
  factory :tag, class: Sequencescape::Api::V2::Tag do
    skip_create

    sequence(:map_id) { |i| i }
    sequence(:oligo) { |_index| generate_oligo }
    tag_group { create :tag_group, test_tags: [instance] }
  end

  factory :tag_group, class: Sequencescape::Api::V2::TagGroup do
    skip_create

    transient { test_tags { [] } }
    sequence(:name) { |index| "TagGroup#{index}" }
    tags { test_tags.map { |t| { index: t.map_id, oligo: t.oligo } } }

    factory :tag_group_with_tags do
      transient do
        size { 96 }
        test_tags { (1..size).map { |i| create(:tag, map_id: i, tag_group: instance) } }
      end
    end
  end
end
