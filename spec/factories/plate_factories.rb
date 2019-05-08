# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :v2_plate, class: Sequencescape::Api::V2::Plate, traits: [:barcoded_v2] do
    initialize_with do
      Sequencescape::Api::V2::Plate.load(attributes)
    end
    skip_create

    transient do
      well_count { number_of_rows * number_of_columns }
      well_factory { :v2_well }
      request_factory { :library_request }
      well_uuid_result { "#{barcode_number}-well-%s" }
      outer_requests do
        request_index = -1
        pool_sizes.each_with_index.flat_map do |size, index|
          Array.new(size) do
            create request_factory,
                   pcr_cycles: pool_prc_cycles[index],
                   state: library_state[index],
                   submission_id: index,
                   include_submissions: include_submissions,
                   order_id: index * 2,
                   uuid: "request-#{request_index += 1}"
          end
        end
      end
      wells do
        Array.new(well_count) do |i|
          location = WellHelpers.well_at_column_index(i, size)
          create well_factory, location: location,
                               state: well_states[i] || state,
                               outer_request: outer_requests[i],
                               downstream_tubes: transfer_targets[location],
                               uuid: well_uuid_result % location,
                               aliquot_count: outer_requests[i] ? 1 : 0
        end
      end
      purpose_name { 'example-purpose' }
      purpose_uuid { 'example-purpose-uuid' }
      purpose { create :v2_purpose, name: purpose_name, uuid: purpose_uuid }
      pool_sizes { [] }
      parents { [] }
      children { [] }
      descendants { [] }
      pool_prc_cycles { Array.new(pool_sizes.length, 10) }
      library_state { ['pending'] * pool_sizes.length }
      stock_plate { create :v2_stock_plate_for_plate, barcode_number: is_stock ? barcode_number : 2 }
      ancestors { [stock_plate] }
      transfer_targets { {} }
      size { 96 }
      include_submissions { false }
      well_states { [state] * size }
      custom_metadatum_collection { nil }
      is_stock { false }
    end

    sequence(:id) { |i| i }
    uuid { SecureRandom.uuid }
    number_of_rows { (((size / 6)**0.5) * 2).floor }
    number_of_columns { (((size / 6)**0.5) * 3).floor }
    state { 'pending' }
    created_at { '2017-06-29T09:31:59.000+01:00' }
    updated_at { '2017-06-29T09:31:59.000+01:00' }

    # Mock the relationships. Should probably handle this all a bit differently
    after(:build) do |plate, evaluator|
      RSpec::Mocks.allow_message(plate, :wells).and_return(evaluator.wells)
      RSpec::Mocks.allow_message(plate, :purpose).and_return(evaluator.purpose)
      RSpec::Mocks.allow_message(plate, :custom_metadatum_collection).and_return(evaluator.custom_metadatum_collection)
      RSpec::Mocks.allow_message(plate, :stock_plate).and_return(evaluator.stock_plate)
      ancestors_scope = JsonApiClient::Query::Builder.new(Sequencescape::Api::V2::Asset)

      # Mock the behaviour of the search
      # This is all a bit inelegant at the moment.
      RSpec::Mocks.allow_message(ancestors_scope, :where) do |parameters|
        evaluator.ancestors.select { |a| parameters[:purpose_name].include?(a.purpose.name) }
      end
      RSpec::Mocks.allow_message(plate, :ancestors).and_return(ancestors_scope)
      RSpec::Mocks.allow_message(plate, :parents).and_return(evaluator.parents)
    end

    factory :v2_stock_plate do
      transient do
        barcode_number { 2 }
        well_factory { :v2_stock_well }
        purpose_name { 'Limber Cherrypicked' }
        purpose_uuid { 'stock-plate-purpose-uuid' }
        ancestors { [] }
        is_stock { true }
      end
    end

    factory :v2_plate_with_primer_panels do
      transient do
        purpose_name { 'Primer Panel example' }
        request_factory { :gbs_library_request }
      end
    end

    factory :v2_plate_for_pooling do
      transient do
        purpose_name { 'Pooled example' }
        request_factory { :isc_library_request }
        pool_sizes { [2] }
      end
    end

    factory :unpassed_plate do
      pool_sizes { [2, 2] }
    end

    factory :passed_plate do
      transient do
        for_multiplexing { true }
        pool_sizes { [2, 2] }
        request_type { 'limber_multiplexing' }
        request_factory { :mx_request }
      end
    end
  end

  factory :v2_stock_plate_for_plate, class: Sequencescape::Api::V2::Plate, traits: [:barcoded_v2] do
    initialize_with do
      Sequencescape::Api::V2::Plate.load(attributes)
    end
    skip_create

    transient do
      barcode_number { 2 }
      well_factory { :v2_stock_well }
      purpose_name { 'Limber Cherrypicked' }
      purpose_uuid { 'stock-plate-purpose-uuid' }
      purpose { create :v2_purpose, name: purpose_name, uuid: purpose_uuid }
      ancestors { [] }
    end

    after(:build) do |plate, evaluator|
      RSpec::Mocks.allow_message(plate, :purpose).and_return(evaluator.purpose)
    end
   end

  factory :plate, class: Limber::Plate, traits: %i[api_object barcoded] do
    json_root { 'plate' }
    size { 96 }
    state { 'pending' }
    created_at { Time.current.to_s }
    updated_at { Time.current.to_s }
    priority { 0 }

    transient do
      barcode_prefix { 'DN' }
      barcode_type { 1 }
      purpose_name { 'example-purpose' }
      purpose_uuid { 'example-purpose-uuid' }
      pool_sizes   { [] }
      empty_wells { [] }
      library_type { 'Standard' }
      request_type { 'Limber Library Creation' }
      stock_plate_barcode { 2 }
      pool_prc_cycles { Array.new(pool_sizes.length, 10) }
      for_multiplexing { false }
      pool_for_multiplexing { [for_multiplexing] * pool_sizes.length }
      pool_complete { false }
    end

    with_has_many_associations 'wells', 'comments', 'creation_transfers', 'qc_files',
                               'requests', 'source_transfers', 'submission_pools', 'transfers_to_tubes',
                               'transfer_request_collections'

    has_pools_hash

    pre_cap_groups { {} }

    plate_purpose do
      {
        'actions' => { 'read' => api_root + purpose_uuid },
        'uuid' => purpose_uuid,
        'name' => purpose_name
      }
    end

    label do
      {
        prefix: 'Limber',
        text: 'Cherrypicked'
      }
    end

    stock_plate do
      sp = associated(:stock_plate, barcode_number: stock_plate_barcode)
      { uuid: sp[:uuid], barcode: sp[:barcode] }
    end

    factory :stock_plate do
      purpose_name { 'Limber Cherrypicked' }
      purpose_uuid { 'stock-plate-purpose-uuid' }
      stock_plate { { barcode: barcode, uuid: uuid } }

      factory :stock_plate_with_metadata do
        with_belongs_to_associations 'custom_metadatum_collection'
      end
    end
  end

  trait :has_pools_hash do
    transient do
      extra_pool_info { {} }
      empty_wells { [] }
    end
    pools do
      wells = WellHelpers.column_order(size).dup
      pooled_wells = wells.reject { |w| empty_wells.include?(w) }
      pool_hash = {}
      pool_sizes.each_with_index do |pool_size, index|
        pool_hash["pool-#{index + 1}-uuid"] = {
          'wells' => pooled_wells.shift(pool_size).sort_by { |well| WellHelpers.row_order(size).index(well) },
          'insert_size' => { from: 100, to: 300 },
          'library_type' => { name: library_type },
          'request_type' => request_type,
          'pcr_cycles' => pool_prc_cycles[index],
          'for_multiplexing' => pool_for_multiplexing[index],
          'pool_complete' => pool_complete
        }.merge(extra_pool_info)
      end
      pool_hash
    end
  end
end
