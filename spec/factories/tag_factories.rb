# frozen_string_literal: true

def generate_oligo
  bases = ['A','T', 'C', 'G']
  min_oligo_size = 6
  max_oligo_size = 10

  (min_oligo_size+rand(max_oligo_size)).times.to_a.map do 
    bases[rand(bases.length)] 
  end.join('')
end


FactoryBot.define do
  factory :v2_tag, class: Sequencescape::Api::V2::Tag do
    skip_create

    sequence(:oligo) {|_index| generate_oligo }
    tag_group { create :v2_tag_group }
  end

  factory :v2_tag_group, class: Sequencescape::Api::V2::Tag do
    skip_create

    sequence(:name) {|index| "TagGroup#{index}" }
  end
end
