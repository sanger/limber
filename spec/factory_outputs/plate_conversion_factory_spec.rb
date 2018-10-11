# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'plate_conversion factory' do
  subject do
    json(
      :plate_conversion,
      uuid: 'example-plate-conversion-uuid'
    )
  end

  let(:json_content) do
    %({
      "plate_conversion": {
        "actions": {
          "read": "http://example.com:3000/example-plate-conversion-uuid"
        },
        "target": {
          "actions": {
            "read": "http://example.com:3000/target-uuid"
          },
          "uuid": "target-uuid"
        },
        "purpose": {
          "actions": {
            "read": "http://example.com:3000/purpose-uuid"
          },
          "uuid": "purpose-uuid"
        },

        "uuid": "example-plate-conversion-uuid"
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['plate_conversion']).to eq JSON.parse(json_content)['plate_conversion']
  end
end
