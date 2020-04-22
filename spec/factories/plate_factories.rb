# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :unmocked_v2_plate, class: Sequencescape::Api::V2::Plate do
    skip_create
  end

  # General purpose factory used to create API V2 plates
  # There is a lot of functionality in here, especially in the transients
  # Setting up requests:
  # request_factory - The factory to use for each request
  # pool_sizes - determined the number of requests on the plate and how they pool
  # outer_requests - More fine-grained controls if the above options aren't suitable
  factory :v2_plate, class: Sequencescape::Api::V2::Plate, traits: [:barcoded_v2] do
    skip_create

    initialize_with do
      Sequencescape::Api::V2::Plate.load(attributes)
    end

    transient do
      # The number of wells on the plate. Usualy calculated from
      # the plate dimensions.
      well_count { number_of_rows * number_of_columns }
      # The factory to use for wells on the plate
      well_factory { :v2_well }
      # The factory to use for requests associated with the plate.
      # For v2_plates this is associated with the aliquot, for v2_stock_plates
      # these requests are coming from the wells themselves
      request_factory { :library_request }
      # Wells have predictable 'uuids' in tests for example: DN12345-well-A1
      # Overide this parameter if you wish to change this format.
      well_uuid_result { "#{barcode_number}-well-%s" }
      # Built automatically by default (using the request_factory) and the information
      # in pool sizes.
      # This is an array of all requests associated with the plate.
      # Generally you only need to overide this if you want fine control
      # over the requests associated with a plate.
      outer_requests do
        request_index = -1
        pool_sizes.each_with_index.flat_map do |pool_size, index|
          Array.new(pool_size) do
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
      # Constructs the wells for the plate. Constructs
      # well_count wells using the factory specified in well_factory
      # Sets requests on wells by pulling them off the outer_request array
      # Wells without requests will be empty.
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
      # Overide the purpose name
      purpose_name { 'example-purpose' }
      # Overive the purpose uuid
      purpose_uuid { 'example-purpose-uuid' }
      # The plate purpose
      purpose { create :v2_purpose, name: purpose_name, uuid: purpose_uuid }
      # Sets up the pools on the plate. Used by outer_requests to work out which
      # requests to build, and which pools (ie. submissions) to assign them to.
      # eg pool_sizes [96] will result in a plate with one pool of 96 requests
      #    pool_sizes [8,8,8] will result in three pools of 8 wells each.
      pool_sizes { [] }
      parents { [] }
      children { [] }
      descendants { [] }
      # Array of pcr_cycles set up for each pool
      pool_prc_cycles { Array.new(pool_sizes.length, 10) }
      # The state of the library request for each pool
      library_state { ['pending'] * pool_sizes.length }
      stock_plate { create :v2_stock_plate_for_plate, barcode_number: is_stock ? barcode_number : 2 }
      ancestors { [stock_plate] }
      transfer_targets { {} }
      # Sets the plate size
      size { 96 }
      include_submissions { false }
      # Array of states for individual wells, used to overide plate state for, eg. failed wells
      well_states { [state] * size }
      is_stock { false }
    end

    sequence(:id) { |i| i }
    uuid
    # Number of rows is calculated from the size by default
    number_of_rows { (((size / 6)**0.5) * 2).floor }
    # Number of columns is calculated from the size by default
    number_of_columns { (((size / 6)**0.5) * 3).floor }
    # The state of the plate. Can overide for individual wells using
    # well_states
    state { 'pending' }
    created_at { '2017-06-29T09:31:59.000+01:00' }
    updated_at { '2017-06-29T09:31:59.000+01:00' }
    custom_metadatum_collection { nil }

    # Set up the relationships.
    # json_client_api handles assigning of relationship information in a frustrating manner
    # which isn't amenable to setting up objects for testing. Instead it tends to strip
    # the attributes off the associated records, leaving just a type and an id. This is not
    # useful if you want to use this data later.
    # Even more frustratingly is that if you attempt to bypass this and set the attribute directly
    # the getter attempts to fetch the object via a cache instead.
    # Here we populate the cache directly with the objects we want. This is *MUCH* faster
    # than achieving the same through mocks.
    # We could probably avoid needing to do anything sneaky at all if we instead generated
    # json-api data and generated the objects from that.
    after(:build) do |plate, evaluator|
      plate._cached_relationship(:wells) { evaluator.wells }
      plate._cached_relationship(:purpose) { evaluator.purpose }
      plate._cached_relationship(:custom_metadatum_collection) { evaluator.custom_metadatum_collection }
      # TODO: Tidy up this to reduce the mocking.
      RSpec::Mocks.allow_message(plate, :stock_plate).and_return(evaluator.stock_plate)

      ancestors_scope = JsonApiClient::Query::Builder.new(Sequencescape::Api::V2::Asset)

      # Mock the behaviour of the search
      # This is all a bit inelegant at the moment.
      RSpec::Mocks.allow_message(ancestors_scope, :where) do |parameters|
        evaluator.ancestors.select { |a| parameters[:purpose_name].include?(a.purpose.name) }
      end
      RSpec::Mocks.allow_message(plate, :ancestors).and_return(ancestors_scope)
      plate._cached_relationship(:parents) { evaluator.parents }
    end

    # Set up a stock plate. Changed behaviour relative to stock plate:
    # - The plate purpose
    # - The well factory to v2_stock_well which sets requests coming out of the wells,
    #   rather than on the aliquots
    # - Sets is_stock to true, which ensures the stock_plate matches itself
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

    # Sets up a plate of GBS requests with configured primer panels
    # Use pool_sizes to determine how many wells have requests
    factory :v2_plate_with_primer_panels do
      initialize_with do
        Sequencescape::Api::V2::Plate.load(attributes)
      end
      transient do
        purpose_name { 'Primer Panel example' }
        request_factory { :gbs_library_request }
      end
    end

    # Sets up a plate of 2 isd requests, complete with bait libraries
    factory :v2_plate_for_pooling do
      transient do
        purpose_name { 'Pooled example' }
        request_factory { :isc_library_request }
        pool_sizes { [2] }
      end
    end

    # Sets up a basic plate with two pools of 2 requests
    factory :unpassed_plate do
      pool_sizes { [2, 2] }
    end

    # Sets up a plate similar to Lib PCR XP plates
    # in which the initial libraries have been created and passed
    # and we are about to begin pooling
    factory :passed_plate do
      transient do
        for_multiplexing { true }
        pool_sizes { [2, 2] }
        request_type { 'limber_multiplexing' }
        request_factory { :mx_request }
      end
    end

    # Sets up a plate at the begining of the agregation process
    # with two submissions of two requests each
    factory :v2_plate_for_aggregation do
      transient do
        purpose_name { 'Limber Bespoke Aggregation' }
        request_factory { :aggregation_request }
        include_submissions { true }
        pool_sizes { [2, 2] }
      end
    end
  end

  # Dummy stock plate for the stock_plate association
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
      plate._cached_relationship(:purpose) { evaluator.purpose }
    end
  end

  # Basic API v1 plate
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

    factory :plate_with_metadata do
      with_belongs_to_associations 'custom_metadatum_collection'
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

  # Adds the pools hash to v1 plates.
  # This is mostly legacy now and is barely used.
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
