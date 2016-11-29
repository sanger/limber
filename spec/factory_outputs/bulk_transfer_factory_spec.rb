# frozen_string_literal: true
require 'rails_helper'

describe 'bulk_transfer factory' do
  subject do
    json(
      :bulk_transfer,
      uuid: 'example-bulk-transfer-uuid',
      transfers_count: 4
    )
  end

  let(:json_content) do
    %({
        "bulk_transfer": {
          "actions": {"read": "http://example.com:300/example-bulk-transfer-uuid"},
          "transfers": {
            "size":4,
            "actions": { "read": "http://example.com:300/example-bulk-transfer-uuid/transfers" }
          },
          "uuid": "example-bulk-transfer-uuid"
        }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['bulk_transfer']).to eq JSON.parse(json_content)['bulk_transfer']
  end
end
