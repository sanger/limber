# frozen_string_literal: true

require_relative '../support/json_renderers'

FactoryBot.define do
  sequence(:barcode_number) { |i| i + 9 } # Add 9 to the sequence to avoid clashes with a few fixed barcodes

  # Base trait for building V1 API classes, do not use directly, instead use
  # :api_object or :api_simple_object
  trait :_api_object do
    skip_create

    transient do
      api_root { 'http://example.com:3000/' } # The root of the Sequencescape API V1

      # A Sequencescape::Api object
      # @note Currently requires the root to be mocked with something like webmock
      api do
        Sequencescape::Api.new(
          url: api_root, cookie: nil,
          namespace: Limber, authorisation: 'testing'
        )
      end
    end

    # A class to handle JSON rendering (mimic an API response)
    json_render { JsonRenderer }

    # The root of the returned JSON. Usually the class name in snake case
    # Ideally we'd generate this from the class itself, but FactoryBot doesn't appear to
    # expose sufficient introspection.
    json_root { 'please define json_root on factory' }
  end

  # Builds an API V1 object with uuids and appropriate actions
  trait :api_object do
    _api_object

    transient do
      # A list of actions available on the resource
      # Read only resources are usually just %w[read]
      resource_actions { ['read'] }
      named_actions { [] }
      resource_url  { api_root + uuid }
    end

    uuid
    actions do
      {}.tap do |action|
        resource_actions.each { |action_name| action[action_name] = resource_url }
        named_actions.each { |action_name| action[action_name] = "#{resource_url}/#{action_name}" }
      end
    end

    initialize_with do
      new(api, json_render.new(json_root, attributes.except(:json_render, :json_root)).to_hash)
    end
  end

  # Used for API V1 objects which do NOT have a uuid (such as submission pool)
  trait :api_simple_object do
    _api_object

    initialize_with do
      new(api, json_render.new(json_root, attributes.except(:json_render, :json_root, :uuid, 'actions')).to_hash)
    end
  end

  # Adds a uuid attribute
  trait :uuid do
    uuid { SecureRandom.uuid }
  end

  # Base trait for barcode behaviour. Sets up shared behaviour. Use the other barcoded traits.
  trait :_barcoded do
    transient do
      barcode_prefix { 'DN' }
      barcode_number
      barcode_object { SBCF::SangerBarcode.new(prefix: barcode_prefix, number: barcode_number) }
      ean13 { barcode_object.machine_barcode.to_s }
      human_barcode { barcode_object.human_barcode }
    end
  end

  # Add to API_V1 Factories to add a barcode
  trait :barcoded do
    _barcoded

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

  # Add to API_V1 Factories to add a legacy ean13 barcode
  trait :ean13_barcoded do
    _barcoded

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

  # Add to API_V2 Factories to add a barcode
  trait :barcoded_v2 do
    _barcoded

    labware_barcode do
      {
        'ean13_barcode' => barcode_object.machine_barcode.to_s,
        'human_barcode' => barcode_object.human_barcode,
        'machine_barcode' => barcode_object.human_barcode # Mimics a code39 printed barcode
      }
    end
  end

  # Add to API_V2 Factories to add a legacy ean13 barcode
  trait :ean13_barcoded_v2 do
    _barcoded

    labware_barcode do
      {
        'ean13_barcode' => barcode_object.machine_barcode.to_s,
        'human_barcode' => barcode_object.human_barcode,
        'machine_barcode' => barcode_object.machine_barcode.to_s
      }
    end
  end
end
