FactoryGirl.define do
  factory :tube_printer, class: Sequencescape::BarcodePrinter, traits: [:api_object] do

    json_root 'barcode_printer'

    name 'tube_printer'

    type do
      {
        layout: 2,
        name: '1D Tube'
      }
    end
  end
end