
# frozen_string_literal: true
FactoryGirl.define do
  factory :transfer_template, class: Sequencescape::TransferTemplate, traits: [:api_object] do
    json_root 'transfer_template'
    name 'Test transfers'
    named_actions ['preview']
    resource_actions %w(read create)
    transfers('A1' => 'A1', 'B1' => 'B1')

    factory :transfer_to_specific_tubes_by_submission do
      name 'Transfer wells to specific tubes defined by submission'
      uuid 'transfer-to-wells-by-submission-uuid'
      transfers nil
    end
  end

  # Builds all the transfer templates we're going to actually be using.
  factory :transfer_template_collection, class: Sequencescape::Api::Associations::HasMany::AssociationProxy, traits: [:api_object] do
    size { available_templates.length }

    transient do
      json_root nil
      resource_actions %w(read first last)
      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}transfer_templates" }
      uuid nil
      available_templates [:transfer_template, :transfer_to_specific_tubes_by_submission]
    end

    transfer_templates do
      available_templates.map { |template| associated(template) }
    end
  end
end
