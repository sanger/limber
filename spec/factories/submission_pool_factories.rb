# frozen_string_literal: true

require_relative '../support/json_renderers'

FactoryBot.define do
  # The following factory is used for setting up a submission_pools collection
  # for a v2 plate.
  factory :v2_submission_pool, class: Sequencescape::Api::V2::SubmissionPool do
    skip_create

    transient do
      used_template_uuids { Array.new(plates_in_submission) { SecureRandom.uuid } }
      tag_layout_templates { used_template_uuids.map { |uuid| create(:v2_tag_layout_template, uuid:) } }
    end

    plates_in_submission { 1 }

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) do |submission_pool, factory|
      if factory.tag_layout_templates
        submission_pool._cached_relationship(:tag_layout_templates) { factory.tag_layout_templates }
      end
    end

    factory :v2_dual_submission_pool do
      plates_in_submission { 2 }
    end
  end
end
