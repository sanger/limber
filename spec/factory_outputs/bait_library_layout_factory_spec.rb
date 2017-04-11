# frozen_string_literal: true

require 'rails_helper'

describe 'bait library layout factory' do
  subject do
    json(
      :bait_library_layout,
      plate_uuid: 'plate-uuid',
      uuid: 'bait-library-layout-uuid'
    )
  end

  let(:json_content) do
    %({
      "bait_library_layout": {
        "actions": {"read": "http://example.com:3000/bait-library-layout-uuid"},
        "plate": {
          "actions": {
            "read": "http://example.com:3000/plate-uuid"
          },
          "uuid": "plate-uuid"
        },
        "uuid": "bait-library-layout-uuid",
        "layout": {
          "A1":  "Human all exon 50MB",
          "B1":  "Human all exon 50MB",
          "C1":  "Mouse all exon",
          "D1":  "Mouse all exon"
        }
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['bait_library_layout']).to eq JSON.parse(json_content)['bait_library_layout']
  end
end
