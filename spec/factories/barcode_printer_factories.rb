
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
      layouts { { 'plate' => 1, 'tube' => 2 } }
    end

    type do
      {
        'name' => printer_type,
        'layout' => layouts[printer_type]
      }
    end

    name { "#{printer_type} printer" }
  end

  factory :barcode_printer_collection, class: Sequencescape::Api::Associations::HasMany::AssociationProxy, traits: [:api_object] do
    size 2

    transient do
      locations { WellHelpers.column_order.slice(0, size) }
      json_root nil
      resource_actions %w(read first last)
      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}/barcode_printers/1" }
      uuid nil
    end

    barcode_printers do
      Array.new(size) { associated(:barcode_printer) }
    end
  end
end
