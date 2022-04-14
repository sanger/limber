# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'work completion factory' do
  subject do
    json(
      :work_completion,
      target_uuid: 'example-target-uuid',
      user_uuid: 'example-user-uuid',
      submissions_count: 1,
      uuid: 'example-work-completion-uuid'
    )
  end

  let(:json_content) do
    '{
        "work_completion": {
          "actions": {
            "read": "http://example.com:3000/example-work-completion-uuid"
          },
          "target": {
            "actions": {
              "read": "http://example.com:3000/example-target-uuid"
            }
          },
          "user": {
            "actions": {
              "read": "http://example.com:3000/example-user-uuid"
            }
          },
          "submissions": {
            "size": 1
          }
        }
    }'
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
  end
end
