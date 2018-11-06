# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'multiplexed_library_tube factory' do
  subject do
    json(
      :multiplexed_library_tube,
      uuid: 'example-multiplexed-library-tube-uuid',
      barcode_number: 123_456,
      stock_plate: {
        "barcode": {
          "ean13": '1111111111111',
          "number": '427444',
          "prefix": 'DN',
          "two_dimensional": nil,
          "type": 1
        },
        "uuid": 'example-stock-plate-uuid'
      }
    )
  end

  let(:json_content) do
    %({
        "multiplexed_library_tube": {
          "actions": {
            "read": "http://example.com:3000/example-multiplexed-library-tube-uuid"
          },
          "requests": {
            "size": 0,
            "actions": {
              "read": "http://example.com:3000/example-multiplexed-library-tube-uuid/requests"
            }
          },
          "qc_files": {
            "size": 0,
            "actions": {
              "read": "http://example.com:3000/example-multiplexed-library-tube-uuid/qc_files"
            }
          },
          "purpose": {
            "name": "Example Purpose",
            "uuid": "example-purpose-uuid"
          },
          "barcode": {
            "prefix": "NT",
            "number": "123456",
            "two_dimensional": null,
            "ean13": "3980123456878",
            "type": 1
          },
          "uuid": "example-multiplexed-library-tube-uuid",
          "stock_plate": {
            "barcode": {
              "ean13": "1111111111111",
              "number": "427444",
              "prefix": "DN",
              "two_dimensional": null,
              "type": 1
            },
            "uuid": "example-stock-plate-uuid"
          }
        }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
    #  expect(JSON.parse(subject)['multiplexed_library_tube']).to eq JSON.parse(json_content)['multiplexed_library_tube']
  end
end
