# frozen_string_literal: true

FactoryBot.define do
  # Build an API v1 barcode printer. You probably want to use: plate_barcode_printer or
  # tube_barcode_printer instead
  factory :barcode_printer, class: Sequencescape::BarcodePrinter, traits: [:api_object] do
    json_root { 'barcode_printer' }

    active { true } # Whether Sequencescape reports the printer as active or not
    service { { 'url' => 'DEPRECATED' } } # Previously the URL of the SOAP barcode printing service. Now deprecated.
    print_service { 'PMB' }

    transient do
      # The type of printer, either 'plate' or 'tube'. Use this to set the layout and name to something
      # appropriate
      printer_type { 'plate' }

      # Sets the type.name attribute. Use printer_type to set this automatically
      printer_type_name { { 'plate' => '96 Well Plate', 'tube' => '1D Tube' }.fetch(printer_type) }

      # Sets the type.layout attribute. Use printer_type to set this automatically.
      layout { { 'plate' => 1, 'tube' => 2 }.fetch(printer_type) }
    end

    # Type is a hash provided by the Sequencescape API which describes the label type
    # loaded into the printer.
    type { { 'name' => printer_type_name, 'layout' => layout } }

    name { "#{printer_type} printer" }

    after(:build) do |barcode_printer, evaluator|
      RSpec::Mocks.allow_message(barcode_printer, :type).and_return(evaluator.type)
    end

    # Build an API V1 plate barcode printer
    factory :plate_barcode_printer do
      transient { printer_type { 'plate' } }
    end

    # Build an API V1 tube barcode printer
    factory :tube_barcode_printer do
      transient { printer_type { 'tube' } }
    end
  end

  factory :barcode_printer_collection, class: Sequencescape::Api::PageOfResults, traits: [:api_object] do
    size { tube_printer_size + plate_printer_size }

    transient do
      tube_printer_size { 2 }
      plate_printer_size { 2 }
      json_root { nil }
      resource_actions { %w[read first last] }
      resource_url { "#{api_root}/barcode_printers/1" }
      uuid { nil }
    end

    barcode_printers do
      Array.new(tube_printer_size) { |i| associated(:plate_barcode_printer, name: "plate printer #{i}") } +
        Array.new(plate_printer_size) { |i| associated(:tube_barcode_printer, name: "tube printer #{i}") }
    end
  end

  # Build an API v2 JSONAPI barcode printer.
  factory :v2_barcode_printer, class: Sequencescape::Api::V2::BarcodePrinter do
    skip_create
    type { 'barcode_printers' }
    uuid
    sequence(:id, &:to_s)
    sequence(:name) { |n| "Barcode Printer #{n}" }
    print_service { 'PMB' }
    type_name { nil }

    factory :v2_plate_barcode_printer do
      type_name { '96 Well Plate' }
    end

    factory :v2_tube_barcode_printer do
      type_name { '1D Tube' }
    end
  end
end
