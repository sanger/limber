# frozen_string_literal: true
require './lib/well_helpers'
require_relative '../support/factory_girl_extensions'

FactoryGirl.define do
  factory :plate, class: Limber::Plate, traits: [:api_object, :barcoded] do
    json_root 'plate'
    size 96
    state 'pending'

    transient do
      barcode_prefix 'DN'
      barcode_type 1
    end

    with_has_many_associations 'wells', 'comments', 'creation_transfers', 'qc_files',
                               'requests', 'source_transfers', 'submission_pools', 'transfers_to_tubes'

    transient do
      purpose_name 'example-purpose'
      purpose_uuid 'ilc-stock-plate-purpose-uuid'
      pool_sizes   []
      library_type 'Standard'
      request_type 'Limber Library Creation'
    end

    pools do
      wells = WellHelpers.column_order.dup
      pool_hash = {}
      pool_sizes.each_with_index do |size, index|
        pool_hash["pool-#{index + 1}-uuid"] = {
          wells: wells.shift(size),
          insert_size: { from: 100, to: 300 },
          library_type: { name: library_type },
          request_type: request_type
        }
      end
      pool_hash
    end

    plate_purpose do
      {
        'actions' => { 'read' => api_root + purpose_uuid },
        'uuid' => purpose_uuid,
        'name' => purpose_name
      }
    end
  end
end
