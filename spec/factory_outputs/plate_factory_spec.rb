# frozen_string_literal: true
require 'rails_helper'

describe 'plate factory' do
  subject do
    json(:plate,
         uuid: 'example-plate-uuid',
         state: 'passed',
         barcode_number: 427_444,
         name: 'Cherrypicked 427444',
         qc_state: nil,
         iteration: 1,
         label: { "prefix": 'RNA-seq dUTP eukaryotic PCR', "text": 'ILC Stock' },
         location: 'Library creation freezer',
         pool_sizes: [8, 8],
         pre_cap_groups: {},
         priority: 0,
         stock_plate: {
           "barcode": {
             "ean13": '1111111111111',
             "number": '427444',
             "prefix": 'DN',
             "two_dimensional": nil,
             "type": 1
           },
           "uuid": 'example-stock-plate-uuid'
         },
         created_at: '2016-01-21 16:08:28 +0000',
         updated_at: '2016-01-21 16:16:42 +0000',
         wells_count: 30,
         comments_count: 3,
         submission_pools_count: 2)
  end

  let(:json_content) do
    %(
    {
      "plate": {
        "created_at": "2016-01-21 16:08:28 +0000",
        "updated_at": "2016-01-21 16:16:42 +0000",
        "comments": {
          "size": 3,
          "actions": {
            "read": "http://localhost:3000/example-plate-uuid/comments"
          }
        },
        "wells": {
          "size": 30,
          "actions": {
            "read": "http://localhost:3000/example-plate-uuid/wells"
          }
        },
        "submission_pools": {
          "size": 2,
          "actions": {
            "read": "http://localhost:3000/example-plate-uuid/submission_pools"
          }
        },
        "requests": {
          "size": 0,
          "actions": {
            "read": "http://localhost:3000/example-plate-uuid/requests"
          }
        },
        "qc_files": {
          "size": 0,
          "actions": {
            "read": "http://localhost:3000/example-plate-uuid/qc_files"
          }
        },
        "source_transfers": {
          "size": 0,
          "actions": {
            "read": "http://localhost:3000/example-plate-uuid/source_transfers"
          }
        },
        "transfers_to_tubes": {
          "size": 0,
          "actions": {
            "read": "http://localhost:3000/example-plate-uuid/transfers_to_tubes"
          }
        },
        "creation_transfers": {
          "size": 0,
          "actions": {
            "read": "http://localhost:3000/example-plate-uuid/creation_transfers"
          }
        },
        "plate_purpose": {
          "actions": {
            "read": "http://localhost:3000/ilc-stock-plate-purpose-uuid"
          },
          "uuid": "ilc-stock-plate-purpose-uuid",
          "name": "example-purpose"
        },
        "actions": {
          "read": "http://localhost:3000/example-plate-uuid"
        },
        "uuid": "example-plate-uuid",
        "name": "Cherrypicked 427444",
        "qc_state": null,
        "barcode": {
          "ean13": "1220427444877",
          "number": "427444",
          "prefix": "DN",
          "two_dimensional": null,
          "type": 1
        },
        "iteration": 1,
        "label": {
          "prefix": "RNA-seq dUTP eukaryotic PCR",
          "text": "ILC Stock"
        },
        "location": "Library creation freezer",
        "pools": {
          "pool-1-uuid": {
            "wells": [
              "A1", "B1", "C1", "D1", "E1", "F1", "G1", "H1"
            ],
            "insert_size": {
              "from": 100,
              "to": 300
            },
            "library_type": {
              "name": "Standard"
            },
            "request_type": "Limber Library Creation"
          },
          "pool-2-uuid": {
            "wells": [
              "A2", "B2", "C2", "D2", "E2", "F2", "G2", "H2"
            ],
            "insert_size": {
              "from": 100,
              "to": 300
            },
            "library_type": {
              "name": "Standard"
            },
            "request_type": "Limber Library Creation"
          }
        },
        "pre_cap_groups": {},
        "priority": 0,
        "size": 96,
        "state": "passed",
        "stock_plate": {
          "barcode": {
            "ean13": "1111111111111",
            "number": "427444",
            "prefix": "DN",
            "two_dimensional": null,
            "type": 1
          },
          "uuid": "example-stock-plate-uuid"
        }
      }
    }
  )
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['plate']).to eq JSON.parse(json_content)['plate']
  end
end
