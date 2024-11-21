# frozen_string_literal: true

FactoryBot.define do
  factory :qc_file, class: Sequencescape::Api::V2::QcFile do
    skip_create

    content_type { 'text/csv' }
    contents { 'example,file,content' }
    created_at { Time.new('2017-06-29T09:31:59.000+01:00') }
    filename { 'file.csv' }
    labware { build(:plate) }
    size { 123 }
    uuid { SecureRandom.uuid }
  end

  # API V1 JSON description of QC file
  factory :v1_qc_file, class: Sequencescape::QcFile, traits: [:api_object] do
    json_root { 'qc_file' }
    filename { 'file.txt' }
    created_at { '2017-06-29T09:31:59.000+01:00' }
    size { 123 }
  end

  # A list of QC files on a plate
  factory :v1_qc_files_collection, class: Sequencescape::Api::PageOfResults, traits: [:api_object] do
    size { 3 }

    transient do
      json_root { nil }
      resource_actions { %w[read first last create] }
      plate_uuid { SecureRandom.uuid }

      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}#{plate_uuid}/qc_files/1" }
      uuid { nil }
    end

    qc_files { Array.new(size) { |i| associated(:qc_file, uuid: "example-file-uuid-#{i}", filename: "file#{i}.txt") } }
  end
end
