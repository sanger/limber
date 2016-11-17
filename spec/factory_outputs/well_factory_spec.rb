# frozen_string_literal: true
require 'rails_helper'

describe 'well factory' do
  subject do
    json(
      :well,
      uuid: 'example-well-uuid',
      location: 'A1'
    )
  end

  # This is a massive oversimplification of the well json, as there is a LOT
  # of unecessary information. We trim our mocks down to what we actually NEED
  let(:json_content) do
    %({
      "well": {
        "actions": {
          "read": "http://localhost:3000/example-well-uuid"
        },
        "uuid": "example-well-uuid",
        "aliquots": [{
          "bait_library":null,
          "insert_size": {},
          "sample": {
            "actions": {
              "read": "http://localhost:3000/example-sample-uuid-0"
            },
            "uuid": "example-sample-uuid-0",
            "reference": {
              "genome": "reference_genome"
            },
            "sanger": {
              "name": "sample_A1_0",
              "sample_id": "SAMA10"
            }
          },
          "tag": {}
        }],
        "location": "A1",
        "state": "pending"
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
  end
end
