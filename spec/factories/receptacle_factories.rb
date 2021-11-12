# frozen_string_literal: true

FactoryBot.define do
  # API v2 receptacle
  factory :v2_receptacle, class: Sequencescape::Api::V2::Receptacle do
    skip_create
    sequence(:id, &:to_s)
    uuid
  end
end
