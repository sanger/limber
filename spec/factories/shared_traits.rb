
# frozen_string_literal: true

require_relative '../support/json_renderers'

FactoryBot.define do
  trait :api_object do
    transient do
      api_root 'http://example.com:3000/'

      api do
        Sequencescape::Api.new(
          url: api_root, cookie: nil,
          namespace: Limber, authorisation: 'testing'
        )
      end

      resource_actions ['read']
      named_actions []
      resource_url  { api_root + uuid }
    end

    json_render JsonRenderer
    json_root 'please define on factory'
    uuid { SecureRandom.uuid }

    actions do
      action = Hash[resource_actions.map { |action_name| [action_name, resource_url] }]
      action.merge Hash[named_actions.map { |action_name| [action_name, resource_url + '/' + action_name] }]
    end

    initialize_with do
      new(api, json_render.new(json_root, attributes).to_hash)
    end
  end

  trait :barcoded do
    transient do
      sequence(:barcode_number) { |i| i }
      ean13 { SBCF::SangerBarcode.new(prefix: barcode_prefix, number: barcode_number).machine_barcode.to_s }
    end

    barcode do
      { 'ean13' => ean13, 'number' => barcode_number.to_s, 'prefix' => barcode_prefix, 'two_dimensional' => nil, 'type' => barcode_type }
    end
  end
end
