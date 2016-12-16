# frozen_string_literal: true
require 'rails_helper'

describe 'plate_purpose factory' do
  subject do
    json(
      :plate_purpose,
      uuid: 'example-plate-purpose-uuid',
      children_count: 1,
      plates_actions: %w(read create)
    )
  end

  let(:json_content) do
    %({
      "plate_purpose": {
        "children": {
          "size": 1,
          "actions": {
            "read": "http://example.com:3000/example-plate-purpose-uuid/children"
          }
        },
        "plates": {
          "size": 0,
          "actions": {
            "read": "http://example.com:3000/example-plate-purpose-uuid/plates",
            "create": "http://example.com:3000/example-plate-purpose-uuid/plates"
          }
        },
        "actions": {
          "read": "http://example.com:3000/example-plate-purpose-uuid"
        },
        "uuid": "example-plate-purpose-uuid",
        "name": "Limber Example Purpose"
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['plate_purpose']).to eq JSON.parse(json_content)['plate_purpose']
  end
end
