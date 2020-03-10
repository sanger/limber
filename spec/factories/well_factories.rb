# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :well, class: Sequencescape::Well, traits: [:api_object] do
    transient do
      sample_count { 1 }
      aliquot_factory { :aliquot }
    end

    json_root { 'well' }
    state { 'pending' }
    location { 'A1' }

    aliquots do
      Array.new(sample_count) do |i|
        associated(aliquot_factory, sample_name: "sample_#{location}_#{i}", sample_id: "SAM#{location}#{i}", sample_uuid: "example-sample-uuid-#{i}")
      end
    end

    factory :empty_well do
      aliquots { [] }
      state { 'unknown' }
    end
  end

  factory :v2_well, class: Sequencescape::Api::V2::Well do
    skip_create

    transient do
      location { 'A1' }
      qc_results { [] }
      aliquot_count { 1 }
      outer_request { create request_factory, state: library_state }
      aliquot_factory { :v2_aliquot }
      aliquots { create_list aliquot_factory, aliquot_count, library_state: library_state, outer_request: outer_request }
      request_factory { :library_request }
      requests_as_source { [] }
      requests_as_target { [] }
      library_state { 'pending' }
      downstream_tubes { [] }
      downstream_assets { [] }
      downstream_plates { [] }
      upstream_tubes { [] }
      upstream_assets { [] }
      upstream_plates { [] }
      plate_barcode { 'DN1S' }
    end

    name { "#{plate_barcode}:#{location}" }
    position { { 'name' => location } }
    state { 'passed' }
    uuid { SecureRandom.uuid }
    pcr_cycles { 14 }

    after(:build) do |well, evaluator|
      RSpec::Mocks.allow_message(well, :qc_results).and_return(evaluator.qc_results || [])
      RSpec::Mocks.allow_message(well, :aliquots).and_return(evaluator.aliquots || [])
      RSpec::Mocks.allow_message(well, :requests_as_source).and_return(evaluator.requests_as_source || [])
      RSpec::Mocks.allow_message(well, :requests_as_target).and_return(evaluator.requests_as_target || [])
      RSpec::Mocks.allow_message(well, :downstream_tubes).and_return(evaluator.downstream_tubes || [])
      RSpec::Mocks.allow_message(well, :downstream_assets).and_return(evaluator.downstream_assets || [])
      RSpec::Mocks.allow_message(well, :downstream_plates).and_return(evaluator.downstream_plates || [])
      RSpec::Mocks.allow_message(well, :upstream_tubes).and_return(evaluator.upstream_tubes || [])
      RSpec::Mocks.allow_message(well, :upstream_assets).and_return(evaluator.upstream_assets || [])
      RSpec::Mocks.allow_message(well, :upstream_plates).and_return(evaluator.upstream_plates || [])
      RSpec::Mocks.allow_message(well, :pcr_cycles).and_return(evaluator.pcr_cycles || [])
    end

    factory :v2_stock_well do
      transient do
        aliquot_factory { :v2_stock_aliquot }
        requests_as_source { [outer_request].compact }
      end
    end

    factory :v2_tagged_well do
      transient { aliquot_factory { :v2_tagged_aliquot } }
    end

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
        RSpec::Mocks.allow_message(well, :transfer_requests_as_source).and_return(evaluator.transfer_requests_as_source || [])
        RSpec::Mocks.allow_message(well, :transfer_requests_as_target).and_return(evaluator.transfer_requests_as_target || [])
      end
    end
  end

  factory :well_collection, class: Sequencescape::Api::Associations::HasMany::AssociationProxy, traits: [:api_object] do
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
          associated(:well, location: location, uuid: "example-well-uuid-#{i}", state: state, aliquot_factory: aliquot_factory)
        end
      end
    end
  end

  factory :aliquot, class: Sequencescape::Behaviour::Receptacle::Aliquot do
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

  factory :v2_aliquot, class: Sequencescape::Api::V2::Aliquot do
    transient do
      library_state { 'pending' }
      outer_request { create :library_request, state: library_state }
      request { outer_request }
      well_location { 'A1' }
    end

    tag_oligo { nil }
    tag_index { nil }
    tag2_oligo { nil }
    tag2_index { nil }
    suboptimal { false }
    sample { create :v2_sample }

    after(:build) do |aliquot, evaluator|
      RSpec::Mocks.allow_message(aliquot, :request).and_return(evaluator.request)
      RSpec::Mocks.allow_message(aliquot, :sample).and_return(evaluator.sample)
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

    factory :v2_stock_aliquot do
      request { nil }
    end

    skip_create
  end

  factory :v2_sample, class: Sequencescape::Api::V2::Sample do
    skip_create
    sequence(:sanger_sample_id) { |i| "sample #{i}" }
    sample_metadata { create(:v2_sample_metadata) }

    after(:build) do |sample, evaluator|
      RSpec::Mocks.allow_message(sample, :sample_metadata).and_return(evaluator.sample_metadata)
    end
  end

  factory :sample, class: Sequencescape::Sample, traits: [:api_object] do
    transient do
      name { 'sample' }
      sample_id { 'SAM1' }
    end

    json_root { 'sample' }

    reference { { 'genome' => 'reference_genome' } }
    sanger    { { 'name' => name, 'sample_id' => sample_id } }
  end

  factory :v2_sample_metadata, class: Sequencescape::Api::V2::SampleMetadata do
    skip_create
    sequence(:supplier_name) { |i| "supplier name #{i}" }
  end
end
