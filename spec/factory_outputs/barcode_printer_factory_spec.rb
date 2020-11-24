# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'barcode printer factory' do
  subject do
    json(
      :barcode_printer,
      uuid: 'example-barcode-printer-uuid',
      printer_type: 'tube'
    )
  end

  let(:json_content) do
    %({
      "barcode_printer": {
        "actions": {
          "read": "http://example.com:3000/example-barcode-printer-uuid"
        },
        "uuid": "example-barcode-printer-uuid",
        "name": "tube printer",
        "print_service": "PMB",
        "active": true,
        "service": {
          "url": "DEPRECATED"
        },
        "type": {
          "name": "1D Tube",
          "layout": 2
        }
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['barcode_printer']).to eq JSON.parse(json_content)['barcode_printer']
  end
end
