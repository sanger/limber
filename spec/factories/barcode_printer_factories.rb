
# frozen_string_literal: true

FactoryGirl.define do
  factory :barcode_printer, class: Sequencescape::BarcodePrinter, traits: [:api_object] do
    json_root 'barcode_printer'
    active true
    service do
      { 'url' => 'http://localhost:9998/barcode_service.wsdl' }
    end

    transient do
      printer_type 'plate'
      printer_type_name { { 'plate' => '96 Well Plate', 'tube' => '1D Tube' }.fetch(printer_type) }
      layout { { 'plate' => 1, 'tube' => 2 }.fetch(printer_type) }
    end

    type do
      {
        'name' => printer_type_name,
        'layout' => layout
      }
    end

    name { "#{printer_type} printer" }

    factory :plate_barcode_printer do
      transient { printer_type 'plate' }
    end

    factory :tube_barcode_printer do
      transient { printer_type 'tube' }
    end
  end

  factory :barcode_printer_collection, class: Sequencescape::Api::Associations::HasMany::AssociationProxy, traits: [:api_object] do
    size { tube_printer_size + plate_printer_size }

    transient do
      tube_printer_size 2
      plate_printer_size 2
      json_root nil
      resource_actions %w(read first last)
      resource_url { "#{api_root}/barcode_printers/1" }
      uuid nil
    end

    barcoder_printers do
      Array.new(tube_printer_size) do |_location, _i|
        associated(:plate_barcode_printer)
      end +
        Array.new(plate_printer_size) do |_location, _i|
          associated(:tube_barcode_printer)
        end
    end
  end
end
