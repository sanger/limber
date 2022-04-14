# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'well factory' do
  subject { json(:well, uuid: 'example-well-uuid', location: 'A1') }

  # This is a massive oversimplification of the well json, as there is a LOT
  # of unecessary information. We trim our mocks down to what we actually NEED
  let(:json_content) do
    '{
      "well": {
        "actions": {
          "read": "http://example.com:3000/example-well-uuid"
        },
        "uuid": "example-well-uuid",
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
              "name": "sample_A1_0",
              "sample_id": "SAMA10"
            }
          },
          "tag": {},
          "tag2": {}
        }],
        "location": "A1",
        "state": "pending"
      }
    }'
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
  end
end

# Has many collections behave somewhat differently. We use a separate factory to help ease the process.
RSpec.describe 'well_collection factory' do
  subject do
    json(
      :well_collection,
      size: 2,
      default_state: 'passed',
      custom_state: {
        'B1' => 'failed'
      },
      plate_uuid: 'plate-uuid'
    )
  end

  let(:json_content) do
    '{
      "actions":{
        "read":"http://example.com:3000/plate-uuid/wells/1",
        "first":"http://example.com:3000/plate-uuid/wells/1",
        "last":"http://example.com:3000/plate-uuid/wells/1"
      },
      "size":2,
      "wells":[{
        "actions": {
          "read": "http://example.com:3000/example-well-uuid-0"
        },
        "uuid": "example-well-uuid-0",
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
              "name": "sample_A1_0",
              "sample_id": "SAMA10"
            }
          },
          "tag": {}
        }],
        "location": "A1",
        "state": "passed"
      },
      {
        "actions": {
          "read": "http://example.com:3000/example-well-uuid-1"
        },
        "uuid": "example-well-uuid-1",
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
              "name": "sample_B1_0",
              "sample_id": "SAMB10"
            }
          },
          "tag": {}
        }],
        "location": "B1",
        "state": "failed"
      }]
    }'
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
  end
end
