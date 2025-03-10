# frozen_string_literal: true

FactoryBot.define do
  # API V2 Project
  factory :v2_project, class: Sequencescape::Api::V2::Project do
    skip_create

    id
    uuid

    name { 'Test Project' }
  end
end
