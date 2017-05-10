
# frozen_string_literal: true

FactoryGirl.define do
  factory :qc_file, class: Sequencescape::QcFile, traits: [:api_object] do
    json_root 'qc_file'
    filename 'file.txt'
  end
end
