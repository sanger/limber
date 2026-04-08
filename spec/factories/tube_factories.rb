# frozen_string_literal: true

FactoryBot.define do
  # API v2 tube
  factory :tube, class: Sequencescape::Api::V2::Tube, traits: [:ean13_barcoded] do
    skip_create

    sequence(:id, &:to_s)
    uuid
    name { 'My tube' }
    type { 'tubes' }
    state { 'passed' }
    purpose_name { 'example-purpose' }
    purpose_uuid { 'example-purpose-uuid' }
    receptacle { create(:receptacle, qc_results: [], aliquots: aliquots, requests_as_source: requests_as_source) }
    sibling_tubes { [{ name: name, uuid: uuid, ean13_barcode: ean13, state: state }] + siblings }
    created_at { '2017-06-29T09:31:59.000+01:00' }
    updated_at { '2017-06-29T09:31:59.000+01:00' }

    transient do
      stock_plate { create :stock_plate }
      ancestors { [stock_plate] }
      barcode_prefix { 'NT' }
      library_state { 'pending' }
      priority { 0 }
      outer_request { create request_factory, state: library_state, priority: priority }
      request_factory { :library_request }
      aliquot_count { 2 }
      aliquot_factory { :tagged_aliquot }
      aliquots { create_list aliquot_factory, aliquot_count, library_state:, outer_request: }
      parents { [] }
      purpose { create :purpose, name: purpose_name, uuid: purpose_uuid }
      racked_tube { nil }
      requests_as_source { [] }

      siblings_count { 0 }
      sibling_default_state { 'passed' }
      siblings do
        Array.new(siblings_count) do |i|
          {
            name: "Sibling #{i + 1}",
            ean13_barcode: (1_234_567_890_123 + i).to_s,
            state: sibling_default_state,
            uuid: "sibling-tube-#{i}"
          }
        end
      end

      # The CustomMetadatumCollection will be cached as a relationship in the after(:build) block.
      custom_metadatum_collection { nil }
    end

    to_create do |instance, _evaluator|
      # JSON API client resources are not persisted in the database, but we need Limber to treat them as if they are.
      # This ensures the `url_for` method will use their UUIDs in URLs via the `to_param` method on the resource.
      # Otherwise it just redirects to the root URL for the resource type.
      instance.mark_as_persisted!
    end

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) do |asset, evaluator|
      asset._cached_relationship(:purpose) { evaluator.purpose }
      ancestors_scope = JsonApiClient::Query::Builder.new(Sequencescape::Api::V2::Asset)

      # Mock the behaviour of the search
      # This is all a bit inelegant at the moment.
      RSpec::Mocks.allow_message(ancestors_scope, :where) do |parameters|
        evaluator.ancestors.select { |a| parameters[:purpose_name].include?(a.purpose.name) }
      end
      asset._cached_relationship(:ancestors) { ancestors_scope }
      asset._cached_relationship(:aliquots) { evaluator.aliquots || [] }
      asset._cached_relationship(:parents) { evaluator.parents }
      asset._cached_relationship(:receptacle) { evaluator.receptacle }
      asset._cached_relationship(:racked_tube) { evaluator.racked_tube }
      asset._cached_relationship(:direct_submissions) { evaluator.direct_submissions || [] }

      if evaluator.custom_metadatum_collection
        asset._cached_relationship(:custom_metadatum_collection) { evaluator.custom_metadatum_collection }
      end
    end

    factory :tube_with_metadata do
      transient { custom_metadatum_collection { create :custom_metadatum_collection } }
    end

    factory :stock_tube do
      ancestors { nil }
      outer_request { nil }

      factory :stock_tube_with_metadata do
        transient { custom_metadatum_collection { create :custom_metadatum_collection } }
      end
    end
  end
end
