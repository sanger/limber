# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'tube factory' do
  subject do
    json(
      :tube,
      uuid: 'example-tube-uuid'
    )
  end

  # This is a massive oversimplification of the tube json, as there is a LOT
  # of unecessary information. We trim our mocks down to what we actually NEED
  let(:json_content) do
    %({
      "tube": {
        "actions": {
          "read": "http://example.com:3000/example-tube-uuid"
        },
        "purpose": {"actions": {}},
        "uuid": "example-tube-uuid",
        "aliquots": [{
          "bait_library":null,
          "insert_size": {},
          "sample": {
            "actions": {
              "read": "http://example.com:3000/example-sample-uuid-0"
            },
            "uuid": "example-sample-uuid-0",
            "reference": {
              "genome": "reference_genome"
            },
            "sanger": {
              "name": "sample_0",
              "sample_id": "SAM0"
            }
          },
          "tag": {}
        }],
        "state": "pending"
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
  end
end
