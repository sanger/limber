FactoryGirl.define do
  factory :printer, class: Sequencescape::BarcodePrinter, traits: [:api_object] do

    json_root 'barcode_printer'

    name 'plate_printer'

    type do
      {
        layout: 1,
        name: '96 Well Plate'
      }
    end
  end
end