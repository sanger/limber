# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'state change factory' do
  subject do
    json(:state_change, target_uuid: 'example-target-uuid', target_state: 'passed', uuid: 'example-state-change-uuid')
  end

  let(:json_content) do
    '{
        "state_change": {
          "actions": {
            "read": "http://example.com:3000/example-state-change-uuid"
          },
          "target": {
            "actions": {
              "read": "http://example.com:3000/example-target-uuid"
            },
            "uuid": "example-target-uuid"
          },
          "target_state": "passed",
          "previous_state": "pending",
          "reason": "testing this works",
          "uuid": "example-state-change-uuid"
        }
    }'
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['state_change']).to eq JSON.parse(json_content)['state_change']
  end
end
