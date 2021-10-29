# frozen_string_literal: true

FactoryBot.define do
  # API V1 multiplexed library tube
  factory :multiplexed_library_tube, class: Limber::MultiplexedLibraryTube, traits: %i[api_object ean13_barcoded] do
    json_root { 'multiplexed_library_tube' }

    transient do
      barcode_prefix { 'NT' }
      barcode_type { 1 }
      purpose_uuid { 'example-purpose-uuid' }
      purpose_name { 'Example Purpose' }
      stock_plate_barcode { 2 }
      aliquot_factory { :tagged_aliquot }
    end

    with_has_many_associations 'requests', 'qc_files', 'studies'
    name { 'Tube' }

    purpose do
      {
        'actions' => { 'read' => api_root + purpose_uuid },
        'uuid' => purpose_uuid, 'name' => purpose_name
      }
    end

    stock_plate do
      sp = associated(:stock_plate, barcode_number: stock_plate_barcode)
      { name: sp[:name], barcode: sp[:barcode] }
    end

    created_at { Time.current }
    updated_at { Time.current }
    state { 'pending' }

    # API V1 tube
    factory :tube, class: Limber::Tube do
      # with_has_many_associations 'aliquots'
      json_root { 'tube' }
      state { 'pending' }

      transient do
        sample_count { 1 }
      end

      aliquots do
        Array.new(sample_count) do |i|
          associated(
            aliquot_factory,
            sample_name: "sample_#{i}",
            sample_id: "SAM#{i}",
            sample_uuid: "example-sample-uuid-#{i}"
          )
        end
      end

      factory :tube_without_siblings do
        json_root { 'tube' }
        sibling_tubes { [{ name: name, uuid: uuid, ean13_barcode: ean13, state: state }] }
      end

      factory :tube_with_siblings do
        json_root { 'tube' }
        transient do
          siblings_count { 1 }
          sibling_default_state { 'passed' }
          other_siblings do
            Array.new(siblings_count) do |i|
              {
                name: "Sibling #{i + 1}",
                ean13_barcode: (1_234_567_890_123 + i).to_s,
                state: sibling_default_state,
                uuid: "sibling-tube-#{i}"
              }
            end
          end
        end

        sibling_tubes do
          [{ name: name, uuid: uuid, ean13_barcode: ean13, state: state }] + other_siblings
        end
      end
    end

    factory :stock_tube do
      purpose_name { 'Limber Cherrypicked' }
      purpose_uuid { 'stock-plate-purpose-uuid' }
      stock_plate { { barcode: barcode, uuid: uuid } }

      factory :stock_tube_with_metadata do
        with_belongs_to_associations 'custom_metadatum_collection'
      end
    end
  end

  # API v2 tube
  factory :v2_tube, class: Sequencescape::Api::V2::Tube, traits: [:ean13_barcoded_v2] do
    skip_create
    sequence(:id, &:to_s)
    uuid
    name { 'My tube' }
    type { 'tubes' }
    state { 'passed' }
    purpose_name { 'example-purpose' }
    purpose_uuid { 'example-purpose-uuid' }
    purpose { create :v2_purpose, name: purpose_name, uuid: purpose_uuid }
    created_at { '2017-06-29T09:31:59.000+01:00' }
    updated_at { '2017-06-29T09:31:59.000+01:00' }

    transient do
      stock_plate { create :v2_stock_plate }
      ancestors { [stock_plate] }
      barcode_prefix { 'NT' }
      library_state { 'pending' }
      priority { 0 }
      outer_request { create request_factory, state: library_state, priority: priority }
      request_factory { :library_request }
      aliquot_count { 2 }
      aliquot_factory { :v2_tagged_aliquot }
      aliquots do
        create_list aliquot_factory, aliquot_count, library_state: library_state, outer_request: outer_request
      end
      parents { [] }
    end

    # Mock the relationships. Should probably handle this all a bit differently
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
    end

    factory :v2_multiplexed_library_tube do
      purpose_name { 'Example Purpose' }
    end

    factory :v2_stock_tube do
      ancestors { nil }
      outer_request { nil }
    end
  end

  factory :tube_collection, class: Sequencescape::Api::PageOfResults, traits: [:api_object] do
    skip_create
    size { 2 }

    transient do
      json_root { nil }
      resource_actions { %w[read first last] }
      purpose_uuid { SecureRandom.uuid }
      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}#{purpose_uuid}/children/1" }
      uuid { nil }
      tube_factory { :tube }
      names { Array.new(size) { |i| "Tube #{i}" } }
    end

    children do
      Array.new(size) { |i| associated(tube_factory, uuid: "tube-#{i}", name: names[i]) }
    end

    factory :single_study_multiplexed_library_tube_collection do
      transient do
        tube_factory { :multiplexed_library_tube }
        study_count { 1 }
      end
      children do
        Array.new(size) do |i|
          associated(tube_factory, uuid: "tube-#{i}", name: names[i], study_count: study_count)
        end
      end
    end
  end
end
