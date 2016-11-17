require 'pry'

FactoryGirl.define do
  factory :plate, class: Limber::Plate, traits: [:api_object] do
    skip_create
    # plate_purpose
    json_root 'plate'

    state 'pending'

    stock_plate do
      {
        barcode:
          {
            prefix: 'DN',
            number: '10'
          }
      }
    end

    barcode do
      {
        prefix: 'DN',
        number: '123',
        ean13: '1234567890123'
      }
    end

    label do
      {
        prefix: 'Limber',
        text: 'Cherrypicked',
      }
    end
  end
end
