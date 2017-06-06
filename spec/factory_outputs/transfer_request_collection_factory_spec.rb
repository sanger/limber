# frozen_string_literal: true

require 'rails_helper'

describe 'transfer_request_collection factory' do
  subject do
    json(
      :transfer_request_collection,
      uuid: 'example-transfer-request-collection-uuid',
      transfer_count: 5,
      number_of_targets: 2
    )
  end

  let(:json_content) do
    %({
        "transfer_request_collection": {
          "actions": {
            "read": "http://example.com:3000/example-transfer-request-collection-uuid"
          },
          "uuid": "example-transfer-request-collection-uuid",
          "transfer_requests": [
            { "source_asset": { "uuid": "example-well-uuid-0"}, "target_asset": { "uuid": "target-0-uuid"} },
            { "source_asset": { "uuid": "example-well-uuid-1"}, "target_asset": { "uuid": "target-0-uuid"} },
            { "source_asset": { "uuid": "example-well-uuid-2"}, "target_asset": { "uuid": "target-0-uuid"} },
            { "source_asset": { "uuid": "example-well-uuid-3"}, "target_asset": { "uuid": "target-1-uuid"} },
            { "source_asset": { "uuid": "example-well-uuid-4"}, "target_asset": { "uuid": "target-1-uuid"} }
          ]
        }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to eq JSON.parse(json_content)
  end
end
