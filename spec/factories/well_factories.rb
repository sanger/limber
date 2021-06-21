# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # API V1 well
  factory :well, class: Sequencescape::Well, traits: [:api_object] do
    transient do
      # Number of aliquots in the well
      sample_count { 1 }
      # Factory to use for aliquots
      aliquot_factory { :aliquot }
    end

    json_root { 'well' }
    state { 'pending' }
    location { 'A1' }

    aliquots do
      Array.new(sample_count) do |i|
        associated(aliquot_factory, sample_name: "sample_#{location}_#{i}", sample_id: "SAM#{location}#{i}",
                                    sample_uuid: "example-sample-uuid-#{i}")
      end
    end

    # Generates an empty well
    factory :empty_well do
      aliquots { [] }
      state { 'unknown' }
    end
  end

  # V2 well
  factory :v2_well, class: Sequencescape::Api::V2::Well do
    initialize_with do
      Sequencescape::Api::V2::Well.load(attributes)
    end

    skip_create

    transient do
      location { 'A1' }
      qc_results { [] }
      # Number of aliquots in the well
      aliquot_count { 1 }
      # The outer request associated with the well via aliquot
      # Use the stock well factory if you want the request comming out of the well
      outer_request { create request_factory, state: library_state }
      # The factory to use for aliquots
      aliquot_factory { :v2_aliquot }
      aliquots do
        # Conditional to avoid generating requests when not required
        if aliquot_count > 0
          create_list aliquot_factory, aliquot_count, outer_request: outer_request
        else
          []
        end
      end
      # The factory to use for outer requests
      request_factory { :library_request }
      # The requests comming out of the well. v2_stock wells will set this based
      # on outer request.
      requests_as_source { [] }
      # Requests terminating at the well. Generally only seen on the final
      # plate of the process after libraries are passed.
      requests_as_target { [] }
      # The state of the ongoing requests.
      library_state { 'pending' }

      # Set up relationships downstream
      # In Sequencescape world these are all populated via the
      # transfer requests
      downstream_tubes { [] }
      downstream_assets { [] }
      downstream_plates { [] }
      upstream_tubes { [] }
      upstream_assets { [] }
      upstream_plates { [] }
      # Plate barcode is used in the well names
      plate_barcode { 'DN1S' }
    end

    name { "#{plate_barcode}:#{location}" }
    position { { 'name' => location } }
    state { 'passed' }
    uuid { SecureRandom.uuid }
    diluent_volume { nil }
    pcr_cycles { nil }
    submit_for_sequencing { nil }
    sub_pool { nil }
    coveraga { nil }

    after(:build) do |well, evaluator|
      well._cached_relationship(:qc_results) { evaluator.qc_results || [] }
      well._cached_relationship(:aliquots) { evaluator.aliquots || [] }
      well._cached_relationship(:requests_as_source) { evaluator.requests_as_source || [] }
      well._cached_relationship(:requests_as_target) { evaluator.requests_as_target || [] }
      well._cached_relationship(:downstream_tubes) { evaluator.downstream_tubes || [] }
      well._cached_relationship(:downstream_assets) { evaluator.downstream_assets || [] }
      well._cached_relationship(:downstream_plates) { evaluator.downstream_plates || [] }
      well._cached_relationship(:upstream_tubes) { evaluator.upstream_tubes || [] }
      well._cached_relationship(:upstream_assets) { evaluator.upstream_assets || [] }
      well._cached_relationship(:upstream_plates) { evaluator.upstream_plates || [] }
      well._cached_relationship(:pcr_cycles) { evaluator.pcr_cycles || [] }
    end

    # API v2 stock wells associate the outer requests with the well requests_as_source,
    # not the aliquots
    factory :v2_stock_well do
      transient do
        aliquot_factory { :v2_stock_aliquot }
        requests_as_source { [outer_request].compact }
      end
    end

    # Tagged wells have tagged aliquots
    factory :v2_tagged_well do
      transient { aliquot_factory { :v2_tagged_aliquot } }
    end

    # Mock in transfer requests into and out of the well
    factory :v2_well_with_transfer_requests do
      transient do
        transfer_request_as_source_volume { 10.0 }
        transfer_request_as_source_target_asset { :v2_well }
        transfer_requests_as_source do
          [create(
            :v2_transfer_request,
            source_asset: nil,
            target_asset: transfer_request_as_source_target_asset,
            volume: transfer_request_as_source_volume
          )]
        end
        transfer_request_as_target_volume { 10.0 }
        transfer_request_as_target_source_asset { :v2_well }
        transfer_requests_as_target do
          [create(
            :v2_transfer_request,
            source_asset: transfer_request_as_target_source_asset,
            target_asset: nil,
            volume: transfer_request_as_target_volume
          )]
        end
      end

      after(:build) do |well, evaluator|
        well._cached_relationship(:transfer_requests_as_source) { evaluator.transfer_requests_as_source || [] }
        well._cached_relationship(:transfer_requests_as_target) { evaluator.transfer_requests_as_target || [] }
      end
    end
  end

  # API V1 collection of wells, used mainly for setting up the well association on v1 plates
  factory :well_collection, class: Sequencescape::Api::PageOfResults, traits: [:api_object] do
    size { 96 }

    transient do
      locations { WellHelpers.column_order.slice(0, size) }
      json_root { nil }
      resource_actions { %w[read first last] }
      plate_uuid   { SecureRandom.uuid }
      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}#{plate_uuid}/wells/1" }
      uuid { nil }
      default_state { 'pending' }
      custom_state { {} }
      aliquot_factory { :aliquot }
      empty_wells { [] }
    end

    wells do
      locations.each_with_index.map do |location, i|
        if empty_wells.include?(location)
          associated(:empty_well, location: location, uuid: "example-well-uuid-#{i}")
        else
          state = custom_state[location] || default_state
          associated(:well, location: location, uuid: "example-well-uuid-#{i}", state: state,
                            aliquot_factory: aliquot_factory)
        end
      end
    end
  end

  # Api V1 Aliquot
  factory :aliquot, class: Sequencescape::Behaviour::Receptacle::Aliquot, traits: [:api_object] do
    bait_library { nil }
    insert_size { {} }
    tag { {} }
    tag2 { {} }
    suboptimal { false }

    sample { associated(:sample, name: sample_name, sample_id: sample_id, uuid: sample_uuid) }

    transient do
      sample_name { 'sample' }
      sample_id   { 'SAM0' }
      sample_uuid { 'example-sample-uuid-0' }
    end

    factory :suboptimal_aliquot do
      suboptimal { true }
    end

    # Dual tagged aliquot
    factory :tagged_aliquot do
      sequence(:tag) do |i|
        {
          name: "Tag #{i}",
          identifier: i,
          oligo: i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G'),
          group: 'My first tag group'
        }
      end
      sequence(:tag2) do |i|
        {
          name: "Tag #{i}",
          identifier: i,
          oligo: i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G'),
          group: 'My first tag group'
        }
      end
    end
  end

  # API V2 aliquot
  factory :v2_aliquot, class: Sequencescape::Api::V2::Aliquot do
    initialize_with do
      Sequencescape::Api::V2::Aliquot.load(attributes)
    end

    transient do
      # State of the ongoing library request
      library_state { 'pending' }
      # Alias for request: The request set on the aliquot itself
      outer_request { create :library_request, state: library_state }
      well_location { 'A1' }
      study_id { 1 }
      project_id { 1 }
    end

    sequence(:id, &:to_s)
    tag_oligo { nil }
    tag_index { nil }
    tag2_oligo { nil }
    tag2_index { nil }
    suboptimal { false }
    sample { create :v2_sample }
    request { outer_request }

    after(:build) do |aliquot, evaluator|
      aliquot._cached_relationship(:request) { evaluator.request }
      aliquot._cached_relationship(:sample) { evaluator.sample }
      aliquot.relationships.study = {
        'links' => {
          'self' => "http://localhost:3000/api/v2/aliquots/#{aliquot.id}/relationships/study",
          'related' => "http://localhost:3000/api/v2/aliquots/#{aliquot.id}/study"
        },
        'data' => { 'type' => 'studies', 'id' => evaluator.study_id.to_s }
      }
      aliquot.relationships.project = {
        'links' => {
          'self' => "http://localhost:3000/api/v2/aliquots/#{aliquot.id}/relationships/project",
          'related' => "http://localhost:3000/api/v2/aliquots/#{aliquot.id}/project"
        },
        'data' => { 'type' => 'projects', 'id' => evaluator.project_id.to_s }
      }
    end

    factory :v2_tagged_aliquot do
      sequence(:tag_oligo) { |i| i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G') }
      tag_index { |_i| (WellHelpers.column_order.index(well_location) || 0) + 1 }
      sequence(:tag2_oligo) { |i| i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G') }
      tag2_index { |_i| (WellHelpers.column_order.index(well_location) || 0) + 1 }
    end

    factory :v2_suboptimal_aliquot do
      suboptimal { true }
    end

    # V2 API stock aliquots. Prevents the request being set on aliquot
    factory :v2_stock_aliquot do
      request { nil }
    end

    skip_create
  end
end
