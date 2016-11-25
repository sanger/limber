
FactoryGirl.define do
  factory :barcode_printer, class: Sequencescape::BarcodePrinter, traits: [:api_object] do
    json_root 'barcode_printer'
    active true
    service do
      {"url" => "http://localhost:9998/barcode_service.wsdl"}
    end

    transient do
      printer_type 'plate'
      layouts {{"plate" => 1, "tube" => 2}}
    end

    type do
      {
        "name" => printer_type,
        "layout" => layouts[printer_type]
      }
    end

    name { "#{printer_type} printer" }

  end
end