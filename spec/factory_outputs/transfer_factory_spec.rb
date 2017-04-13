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

describe 'transfer_to_mx_tubes_by_submission' do
  subject do
    json(
      :transfer_to_mx_tubes_by_submission,
      uuid: 'example-transfer',
      destination_uuid: 'destination-uuid',
      source_uuid: 'source-uuid',
      user_uuid: 'user-uuid',
      target_tubes_count: 2
    )
  end

  # Source and user are actually inline for this one, but we don't especially care.
  let(:json_content) do
    %({
      "transfer":{
        "actions":{"read":"http://example.com:3000/example-transfer"},
        "uuid":"example-transfer",
        "source":{
          "actions":{"read":"http://example.com:3000/source-uuid"},
          "uuid":"source-uuid"
        },
        "user":{
          "actions":{"read":"http://example.com:3000/user-uuid"},
          "uuid":"user-uuid"
        },
        "transfers": {
          "A1":{
            "uuid":"child-tube-0",
            "name":"Child tube 0",
            "state":"pending",
            "label":{"text":"Example purpose","prefix":"prefix"},
            "barcode":{"number":"1","prefix":"NT","two_dimensional":null,"ean13":"3980000001795","type":2}
          },
          "B1":{
            "uuid":"child-tube-1",
            "name":"Child tube 1",
            "state":"pending",
            "label":{"text":"Example purpose","prefix":"prefix"},
            "barcode":{"number":"2","prefix":"NT","two_dimensional":null,"ean13":"3980000002808","type":2}
          }
        }
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
  end
end
