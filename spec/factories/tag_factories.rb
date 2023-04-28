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

    sequence(:oligo) { |_index| generate_oligo }
    tag_group { create :v2_tag_group }
  end

  factory :v2_tag_group, class: Sequencescape::Api::V2::Tag do
    skip_create

    sequence(:name) { |index| "TagGroup#{index}" }
  end
end
