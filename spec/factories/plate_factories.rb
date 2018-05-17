# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :v2_plate, class: Sequencescape::Api::V2::Plate, traits: [:barcoded_v2] do
    skip_create
    transient do
      wells []
      size 96
      pool_sizes   []
      library_type 'Standard'
      request_type 'Limber Library Creation'
      pool_prc_cycles { Array.new(pool_sizes.length, 10) }
      for_multiplexing false
      pool_for_multiplexing { [for_multiplexing] * pool_sizes.length }
      pool_complete false
    end

    has_pools_hash

    after(:build) do |plate, evaluator|
      plate.stub(:wells) { evaluator.wells }
    end
  end

  factory :plate, class: Limber::Plate, traits: %i[api_object barcoded] do
    json_root 'plate'
    size 96
    state 'pending'
    created_at { Time.current.to_s }
    updated_at { Time.current.to_s }
    priority 0

    transient do
      barcode_prefix 'DN'
      barcode_type 1
      purpose_name 'example-purpose'
      purpose_uuid 'example-purpose-uuid'
      pool_sizes   []
      library_type 'Standard'
      request_type 'Limber Library Creation'
      stock_plate_barcode 2
      pool_prc_cycles { Array.new(pool_sizes.length, 10) }
      for_multiplexing false
      pool_for_multiplexing { [for_multiplexing] * pool_sizes.length }
      pool_complete false
    end

    with_has_many_associations 'wells', 'comments', 'creation_transfers', 'qc_files',
                               'requests', 'source_transfers', 'submission_pools', 'transfers_to_tubes',
                               'transfer_request_collections'

    has_pools_hash

    pre_cap_groups({})

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
      purpose_name 'Limber Cherrypicked'
      purpose_uuid 'stock-plate-purpose-uuid'
      stock_plate { { barcode: barcode, uuid: uuid } }

      factory :stock_plate_with_metadata do
        with_belongs_to_associations 'custom_metadatum_collection'
      end
    end

    factory :plate_with_transfers do
      transfers_to_tubes_count 1
    end

    factory :plate_for_pooling do
      purpose_name 'Pooled example'
      pre_cap_groups('pre-cap-group' => { 'wells' => %w[A1 B1] })
    end

    factory :plate_with_primer_panels do
      transient do
        extra_pool_info('primer_panel' => {
                          'name' => 'example panel',
                          'programs' => {
                            'pcr 1' => { 'name' => 'example program', 'duration' => 45 },
                            'pcr 2' => { 'name' => 'other program', 'duration' => 20 }
                          }
                        })
      end
      has_pools_hash
    end

    factory :passed_plate do
      transient do
        for_multiplexing true
        pool_sizes [2, 2]
        request_type 'limber_multiplexing'
      end
    end

    factory :unpassed_plate do
      pool_sizes [2, 2]
    end
  end

  trait :has_pools_hash do
    transient do
      extra_pool_info { {} }
    end
    pools do
      wells = WellHelpers.column_order(size).dup
      pool_hash = {}
      pool_sizes.each_with_index do |pool_size, index|
        pool_hash["pool-#{index + 1}-uuid"] = {
          'wells' => wells.shift(pool_size).sort_by { |well| WellHelpers.row_order(size).index(well) },
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
