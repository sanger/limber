# frozen_string_literal: true
require 'rails_helper'

describe 'transfer_between_tubes_by_submission factory' do
  subject do
    json(
      :transfer_between_tubes_by_submission,
      uuid: 'example-transfer',
      destination_uuid: 'destination-uuid',
      source_uuid: 'source-uuid',
      user_uuid: 'user-uuid'
    )
  end

  let(:json_content) do
    %({
      "transfer":{
        "actions":{"read":"http://example.com:3000/example-transfer"},
        "uuid":"example-transfer",
        "destination":{
          "actions":{"read":"http://example.com:3000/destination-uuid"},
          "uuid":"destination-uuid"
        },
        "source":{
          "actions":{"read":"http://example.com:3000/source-uuid"},
          "uuid":"source-uuid"
        },
        "user":{
          "actions":{"read":"http://example.com:3000/user-uuid"},
          "uuid":"user-uuid"
        }
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
  end
end
