# frozen_string_literal: true

def generate_oligo
  bases = %w[A T C G]
  min_oligo_size = 6
  max_oligo_size = 10

  (min_oligo_size + rand(max_oligo_size)).times.to_a.map { bases[rand(bases.length)] }.join
end

FactoryBot.define do
  factory :v2_tag, class: Sequencescape::Api::V2::Tag do
    skip_create

    sequence(:map_id) { |i| i }
    sequence(:oligo) { |_index| generate_oligo }
    tag_group { create :v2_tag_group, v2_tags: [instance] }
  end

  factory :v2_tag_group, class: Sequencescape::Api::V2::TagGroup do
    skip_create

    transient { v2_tags { [] } }
    sequence(:name) { |index| "TagGroup#{index}" }
    tags { v2_tags.map { |t| { index: t.map_id, oligo: t.oligo } } }

    factory :v2_tag_group_with_tags do
      transient do
        size { 96 }
        v2_tags { (1..size).map { |i| create(:v2_tag, map_id: i) } }
      end
    end
  end
end
