# frozen_string_literal: true
require 'rails_helper'

describe 'multiplexed_library_tube factory' do
  subject do
    json(
      :multiplexed_library_tube,
      uuid: 'example-multiplexed-library-tube-uuid',
      barcode_number: 123_456
    )
  end

  let(:json_content) do
    %({
        "multiplexed_library_tube": {
          "actions": {
            "read": "http://localhost:3000/example-multiplexed-library-tube-uuid"
          },
          "purpose": {
            "uuid": "example-purpose-uuid"
          },
          "barcode": {
            "prefix": "NT",
            "number": "123456",
            "two_dimensional": null,
            "ean13": "3980123456878",
            "type": 1
          },
          "uuid": "example-multiplexed-library-tube-uuid"
        }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['multiplexed_library_tube']).to eq JSON.parse(json_content)['multiplexed_library_tube']
  end
end
