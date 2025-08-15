# frozen_string_literal: true

FactoryBot.define do
  factory :qc_file, class: Sequencescape::Api::V2::QcFile do
    skip_create

    uuid

    content_type { 'text/csv' }
    contents { 'example,file,content' }
    created_at { Time.new('2017-06-29T09:31:59.000+01:00') }
    filename { 'file.csv' }
    labware { build(:v2_plate) }
    size { 123 }
  end
end
