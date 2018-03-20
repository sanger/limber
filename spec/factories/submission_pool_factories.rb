# frozen_string_literal: true

require_relative '../support/json_renderers'

FactoryBot.define do
  # Caution! You probably don't want this one! Submission pools
  # are always accessed via their plate
  factory :submission_pool_base, class: Sequencescape::SubmissionPool do
    plates_in_submission 1
    used_tag2_layout_templates []

    factory :dual_submission_pool_base do
      plates_in_submission 2
    end
  end

  factory :submission_pool_collection, class: Sequencescape::Api::Associations::HasMany::AssociationProxy, traits: [:api_object] do
    size 1

    transient do
      json_root nil
      resource_actions %w[read first last]
      pool_count 1
      uuid nil
      plate_uuid 'plate-uuid'
      resource_url { "#{api_root}#{plate_uuid}/submission_pools/1" }
      used_templates []
    end

    submission_pools do
      Array.new(pool_count) { associated(:submission_pool_base, used_tag2_layout_templates: used_templates) }
    end

    factory :dual_submission_pool_collection do
      submission_pools do
        Array.new(pool_count) { associated(:dual_submission_pool_base, used_tag2_layout_templates: used_templates) }
      end
    end
  end
end
