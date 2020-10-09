# frozen_string_literal: true

FactoryBot.define do
  # Build an API v1 barcode printer. You probably want to use: plate_barcode_printer or
  # tube_barcode_printer instead
  factory :barcode_printer, class: Sequencescape::BarcodePrinter, traits: [:api_object] do
    json_root { 'barcode_printer' }

    active { true } # Whether Sequencescape reports the printer as active or not
    service { { 'url' => 'DEPRECATED' } } # Previously the URL of the SOAP barcode printing service. Now deprecated.

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
    type do
      {
        'name' => printer_type_name,
        'layout' => layout
      }
    end

    name { "#{printer_type} printer" }

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

    barcoder_printers do
      Array.new(tube_printer_size) do |i|
        associated(:plate_barcode_printer, name: "plate printer #{i}")
      end +
        Array.new(plate_printer_size) do |i|
          associated(:tube_barcode_printer, name: "tube printer #{i}")
        end
    end
  end
end
