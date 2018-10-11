# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'specific_tube_creation factory' do
  subject do
    json(
      :specific_tube_creation,
      uuid: 'example-tube-creation-uuid',
      children_count: 1,
      child_purposes_count: 1
    )
  end

  let(:json_content) do
    %({
  "specific_tube_creation": {
    "children": {
      "size": 1,
      "actions": {
        "read": "http://example.com:3000/example-tube-creation-uuid/children"
      }
    },
    "child_purposes": {
      "size": 1,
      "actions": {
        "read": "http://example.com:3000/example-tube-creation-uuid/child_purposes"
      }
    },
    "parent": {},
    "user": {},
    "actions": {
      "read": "http://example.com:3000/example-tube-creation-uuid"
    },
    "uuid": "example-tube-creation-uuid"
  }
})
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
  end
end
