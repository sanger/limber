# frozen_string_literal: true

require_relative '../support/json_renderers'

FactoryBot.define do
  sequence(:barcode_number) { |i| i + 9 } # Add 9 to the sequence to avoid clashes with a few fixed barcodes

  trait :_api_object do
    # Base trait for building V1 API classes, do not use directly, instead use
    # :api_object or api_simple_object
    skip_create
    transient do
      api_root { 'http://example.com:3000/' }

      api do
        Sequencescape::Api.new(
          url: api_root, cookie: nil,
          namespace: Limber, authorisation: 'testing'
        )
      end
    end

    json_render { JsonRenderer }
    json_root { 'please define on factory' }
  end

  trait :api_object do
    # Builds an API V1 object with uuids and appropriate actions
    _api_object

    transient do
      resource_actions { ['read'] }
      named_actions { [] }
      resource_url  { api_root + uuid }
    end

    uuid { SecureRandom.uuid }
    actions do
      action = Hash[resource_actions.map { |action_name| [action_name, resource_url] }]
      action.merge Hash[named_actions.map { |action_name| [action_name, resource_url + '/' + action_name] }]
    end

    initialize_with do
      new(api, json_render.new(json_root, attributes.except(:json_render, :json_root)).to_hash)
    end
  end

  trait :api_simple_object do
    # Used for API V1 objects which do NOT have a uuid (such as submission pool)
    _api_object

    initialize_with do
      new(api, json_render.new(json_root, attributes.except(:json_render, :json_root, :uuid, 'actions')).to_hash)
    end
  end

  trait :uuid do
    uuid { SecureRandom.uuid }
  end

  trait :barcoded do
    transient do
      barcode_number
      barcode_object { SBCF::SangerBarcode.new(prefix: barcode_prefix, number: barcode_number) }
      ean13 { barcode_object.machine_barcode.to_s }
      human_barcode { barcode_object.human_barcode }
      machine_barcode { human_barcode }
    end

    barcode do
      {
        'ean13' => ean13,
        'number' => barcode_number.to_s,
        'prefix' => barcode_prefix,
        'two_dimensional' => nil,
        'type' => barcode_type,
        'machine' => human_barcode
      }
    end
  end

  trait :ean13_barcoded do
    transient do
      barcode_number
      barcode_object { SBCF::SangerBarcode.new(prefix: barcode_prefix, number: barcode_number) }
      ean13 { barcode_object.machine_barcode.to_s }
      human_barcode { barcode_object.human_barcode }
      machine_barcode { human_barcode }
    end

    barcode do
      {
        'ean13' => ean13,
        'number' => barcode_number.to_s,
        'prefix' => barcode_prefix,
        'two_dimensional' => nil,
        'type' => barcode_type,
        'machine' => ean13
      }
    end
  end

  trait :barcoded_v2 do
    transient do
      barcode_number
      barcode_prefix { 'DN' }
      barcode { SBCF::SangerBarcode.new(prefix: barcode_prefix, number: barcode_number) }
    end

    labware_barcode do
      {
        'ean13_barcode' => barcode.machine_barcode.to_s,
        'human_barcode' => barcode.human_barcode,
        'machine_barcode' => barcode.human_barcode # Mimics a code39 printed barcode
      }
    end
  end

  trait :ean13_barcoded_v2 do
    transient do
      barcode_number
      barcode_prefix { 'DN' }
      barcode { SBCF::SangerBarcode.new(prefix: barcode_prefix, number: barcode_number) }
    end

    labware_barcode do
      {
        'ean13_barcode' => barcode.machine_barcode.to_s,
        'human_barcode' => barcode.human_barcode,
        'machine_barcode' => barcode.machine_barcode.to_s
      }
    end
  end
end
