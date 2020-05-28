# frozen_string_literal: true

require_relative '../support/json_renderers'

FactoryBot.define do
  # API V1 submission pool information, usually accessed via the collection on plate
  factory :submission_pool_base, class: Sequencescape::SubmissionPool, traits: [:api_simple_object] do
    # Caution! You probably don't want this one! Submission pools
    # are always accessed via their plate.
    plates_in_submission { 1 }
    used_tag2_layout_templates { [] }
    used_tag_layout_templates { [] }

    factory :dual_submission_pool_base do
      plates_in_submission { 2 }
    end
  end

  # Sets up a submission pool, which tries to report on cross plate submissions in
  # API v1. Used to:
  # - Work out if dual indexing is required (ie. There are multiple plates in the submission)
  # - Indicate which templates have already been used
  factory :submission_pool_collection, class: Sequencescape::Api::PageOfResults, traits: [:api_object] do
    size { 1 }

    transient do
      json_root { nil }
      resource_actions { %w[read first last] }
      # The number of pools associated with the plate. In practice
      # this will likely be 1 for the vast majority of cross plate pools.
      pool_count { 1 }
      uuid { nil }
      plate_uuid { 'plate-uuid' }
      resource_url { "#{api_root}#{plate_uuid}/submission_pools/1" }
      # The tag templates already used
      used_tag_templates { [] }
      # The tag2 templates already used
      used_tag2_templates { [] }
    end

    submission_pools do
      Array.new(pool_count) do
        associated(:submission_pool_base, used_tag2_layout_templates: used_tag2_templates,
                                          used_tag_layout_templates: used_tag_templates)
      end
    end

    # Generates a submission pool with two plates
    factory :dual_submission_pool_collection do
      submission_pools do
        Array.new(pool_count) do
          associated(:dual_submission_pool_base, used_tag2_layout_templates: used_tag2_templates,
                                                 used_tag_layout_templates: used_tag_templates)
        end
      end
    end
  end
end
