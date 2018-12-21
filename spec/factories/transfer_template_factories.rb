# frozen_string_literal: true

FactoryBot.define do
  factory :transfer_template, class: Sequencescape::TransferTemplate, traits: [:api_object] do
    json_root { 'transfer_template' }
    name { 'Test transfers' }
    named_actions { ['preview'] }
    resource_actions { %w[read create] }
    transfers { { 'A1' => 'A1', 'B1' => 'B1' } }
    uuid { 'transfer-template-uuid' }

    factory :transfer_custom_pooling do
      name { 'Custom pooling' }
      uuid { 'custom-pooling' }
      transfers { nil }
    end

    factory :transfer_1_12 do
      name { 'Transfer columns 1-12' }
      uuid { 'transfer-1-12' }
      transfers { WellHelpers.stamp_hash(96) }
    end

    factory :transfer_to_specific_tubes_by_submission do
      name { 'Transfer wells to specific tubes defined by submission' }
      uuid { 'transfer-to-wells-by-submission-uuid' }
      transfers { nil }
    end

    factory :transfer_wells_to_mx_library_tubes_by_submission do
      name { 'Transfer wells to MX library tubes by submission' }
      uuid { 'transfer-to-mx-tubes-on-submission' }
      transfers { nil }
    end

    factory :whole_plate_to_tube do
      name { 'Whole plate to tube' }
      uuid { 'whole-plate-to-tube' }
      transfers { nil }
    end
  end

  # Builds all the transfer templates we're going to actually be using.
  factory :transfer_template_collection, class: Sequencescape::Api::Associations::HasMany::AssociationProxy, traits: [:api_object] do
    size { available_templates.length }

    transient do
      json_root { nil }
      resource_actions { %w[read first last] }
      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}transfer_templates" }
      uuid { nil }
      available_templates { %i[transfer_template transfer_to_specific_tubes_by_submission transfer_custom_pooling] }
    end

    transfer_templates do
      available_templates.map { |template| associated(template) }
    end
  end
end
