# frozen_string_literal: true

require_relative '../support/json_renderers'

FactoryBot.define do
  sequence(:barcode_number) { |i| i + 9 } # Add 9 to the sequence to avoid clashes with a few fixed barcodes

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

  # Add to API_V2 Factories to add a barcode
  trait :barcoded do
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
  trait :ean13_barcoded do
    _barcoded

    labware_barcode do
      {
        'ean13_barcode' => barcode_object.machine_barcode.to_s,
        'human_barcode' => barcode_object.human_barcode,
        'machine_barcode' => barcode_object.machine_barcode.to_s
      }
    end
  end

  sequence(:id, &:to_s)
end
