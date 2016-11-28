# frozen_string_literal: true
require 'rails_helper'

describe 'plate_creation factory' do
  subject do
    json(
      :plate_creation,
      parent_uuid: 'example-parent-uuid',
      child_purpose_uuid: 'example-child-purpose-uuid',
      uuid: 'example-plate-creation-uuid'
    )
  end

  let(:json_content) do
    %({
      "plate_creation": {
        "actions": {
          "read": "http://localhost:3000/example-plate-creation-uuid"
        },
        "parent": {
          "actions": {
            "read": "http://localhost:3000/example-parent-uuid"
          }
        },
        "child": {
          "actions": {
            "read": "http://localhost:3000/child-uuid"
          }
        },
        "child_purpose": {
          "actions": {
            "read": "http://localhost:3000/example-child-purpose-uuid"
          }
        },

        "uuid": "example-plate-creation-uuid"
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['plate_creation']).to eq JSON.parse(json_content)['plate_creation']
  end
end
