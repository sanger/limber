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
          "A2":  "Human all exon 50MB",
          "A3":  "Human all exon 50MB",
          "A4":  "Human all exon 50MB",
          "A5":  "Human all exon 50MB",
          "A6":  "Human all exon 50MB",
          "A7":  "Mouse all exon",
          "A8":  "Mouse all exon",
          "A9":  "Mouse all exon",
          "A10": "Mouse all exon",
          "A11": "Mouse all exon",
          "A12": "Mouse all exon",

          "B1":  "Human all exon 50MB",
          "B2":  "Human all exon 50MB",
          "B3":  "Human all exon 50MB",
          "B4":  "Human all exon 50MB",
          "B5":  "Human all exon 50MB",
          "B6":  "Human all exon 50MB",
          "B7":  "Mouse all exon",
          "B8":  "Mouse all exon",
          "B9":  "Mouse all exon",
          "B10": "Mouse all exon",
          "B11": "Mouse all exon",
          "B12": "Mouse all exon",

          "C1":  "Human all exon 50MB",
          "C2":  "Human all exon 50MB",
          "C3":  "Human all exon 50MB",
          "C4":  "Human all exon 50MB",
          "C5":  "Human all exon 50MB",
          "C6":  "Human all exon 50MB",
          "C7":  "Mouse all exon",
          "C8":  "Mouse all exon",
          "C9":  "Mouse all exon",
          "C10": "Mouse all exon",
          "C11": "Mouse all exon",
          "C12": "Mouse all exon",

          "D1":  "Human all exon 50MB",
          "D2":  "Human all exon 50MB",
          "D3":  "Human all exon 50MB",
          "D4":  "Human all exon 50MB",
          "D5":  "Human all exon 50MB",
          "D6":  "Human all exon 50MB",
          "D7":  "Mouse all exon",
          "D8":  "Mouse all exon",
          "D9":  "Mouse all exon",
          "D10": "Mouse all exon",
          "D11": "Mouse all exon",
          "D12": "Mouse all exon",

          "E1":  "Human all exon 50MB",
          "E2":  "Human all exon 50MB",
          "E3":  "Human all exon 50MB",
          "E4":  "Human all exon 50MB",
          "E5":  "Human all exon 50MB",
          "E6":  "Human all exon 50MB",
          "E7":  "Mouse all exon",
          "E8":  "Mouse all exon",
          "E9":  "Mouse all exon",
          "E10": "Mouse all exon",
          "E11": "Mouse all exon",
          "E12": "Mouse all exon",

          "F1":  "Human all exon 50MB",
          "F2":  "Human all exon 50MB",
          "F3":  "Human all exon 50MB",
          "F4":  "Human all exon 50MB",
          "F5":  "Human all exon 50MB",
          "F6":  "Human all exon 50MB",
          "F7":  "Mouse all exon",
          "F8":  "Mouse all exon",
          "F9":  "Mouse all exon",
          "F10": "Mouse all exon",
          "F11": "Mouse all exon",
          "F12": "Mouse all exon",

          "G1":  "Human all exon 50MB",
          "G2":  "Human all exon 50MB",
          "G3":  "Human all exon 50MB",
          "G4":  "Human all exon 50MB",
          "G5":  "Human all exon 50MB",
          "G6":  "Human all exon 50MB",
          "G7":  "Mouse all exon",
          "G8":  "Mouse all exon",
          "G9":  "Mouse all exon",
          "G10": "Mouse all exon",
          "G11": "Mouse all exon",
          "G12": "Mouse all exon",

          "H1":  "Human all exon 50MB",
          "H2":  "Human all exon 50MB",
          "H3":  "Human all exon 50MB",
          "H4":  "Human all exon 50MB",
          "H5":  "Human all exon 50MB",
          "H6":  "Human all exon 50MB",
          "H7":  "Mouse all exon",
          "H8":  "Mouse all exon",
          "H9":  "Mouse all exon",
          "H10": "Mouse all exon",
          "H11": "Mouse all exon",
          "H12": "Mouse all exon"
        }
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['bait_library_layout']).to eq JSON.parse(json_content)['bait_library_layout']
  end
end
