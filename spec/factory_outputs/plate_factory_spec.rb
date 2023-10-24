# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'plate factory' do
  subject do
    json(
      :plate,
      uuid: 'example-plate-uuid',
      state: 'passed',
      barcode_number: 427_444,
      name: 'Cherrypicked 427444',
      qc_state: nil,
      iteration: 1,
      label: {
        prefix: 'RNA-seq dUTP eukaryotic PCR',
        text: 'ILC Stock'
      },
      location: 'Library creation freezer',
      pool_sizes: [9, 9],
      priority: 0,
      stock_plate: {
        barcode: {
          ean13: '1111111111111',
          number: '427444',
          prefix: 'DN',
          two_dimensional: nil,
          type: 1
        },
        uuid: 'example-stock-plate-uuid'
      },
      created_at: '2016-01-21 16:08:28 +0000',
      updated_at: '2016-01-21 16:16:42 +0000',
      wells_count: 30,
      qc_files_actions: %w[read create],
      comments_count: 3,
      submission_pools_count: 2
    )
  end

  let(:json_content) do
    '
    {
      "plate": {
        "created_at": "2016-01-21 16:08:28 +0000",
        "updated_at": "2016-01-21 16:16:42 +0000",
        "comments": {
          "size": 3,
          "actions": {
            "read": "http://example.com:3000/example-plate-uuid/comments"
          }
        },
        "wells": {
          "size": 30,
          "actions": {
            "read": "http://example.com:3000/example-plate-uuid/wells"
          }
        },
        "submission_pools": {
          "size": 2,
          "actions": {
            "read": "http://example.com:3000/example-plate-uuid/submission_pools"
          }
        },
        "requests": {
          "size": 0,
          "actions": {
            "read": "http://example.com:3000/example-plate-uuid/requests"
          }
        },
        "qc_files": {
          "size": 0,
          "actions": {
            "read": "http://example.com:3000/example-plate-uuid/qc_files",
            "create": "http://example.com:3000/example-plate-uuid/qc_files"
          }
        },
        "source_transfers": {
          "size": 0,
          "actions": {
            "read": "http://example.com:3000/example-plate-uuid/source_transfers"
          }
        },
        "transfer_request_collections": {
          "size": 0,
          "actions": {
            "read": "http://example.com:3000/example-plate-uuid/transfer_request_collections"
          }
        },
        "transfers_to_tubes": {
          "size": 0,
          "actions": {
            "read": "http://example.com:3000/example-plate-uuid/transfers_to_tubes"
          }
        },
        "creation_transfers": {
          "size": 0,
          "actions": {
            "read": "http://example.com:3000/example-plate-uuid/creation_transfers"
          }
        },
        "plate_purpose": {
          "actions": {
            "read": "http://example.com:3000/example-purpose-uuid"
          },
          "uuid": "example-purpose-uuid",
          "name": "example-purpose"
        },
        "actions": {
          "read": "http://example.com:3000/example-plate-uuid"
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
              "A1", "A2", "B1", "C1", "D1", "E1", "F1", "G1", "H1"
            ],
            "insert_size": {
              "from": 100,
              "to": 300
            },
            "library_type": {
              "name": "Standard"
            },
            "request_type": "Limber Library Creation",
            "pcr_cycles": 10
          },
          "pool-2-uuid": {
            "wells": [
              "A3", "B2", "B3", "C2", "D2", "E2", "F2", "G2", "H2"
            ],
            "insert_size": {
              "from": 100,
              "to": 300
            },
            "library_type": {
              "name": "Standard"
            },
            "request_type": "Limber Library Creation",
            "pcr_cycles": 10
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
    }'
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
  end
end

RSpec.describe 'v2_plate' do
  context 'with specified study and project at plate level' do
    subject { create(:v2_plate, aliquots_without_requests: 1, study: study, project: project) }

    # study
    let(:study_uuid) { SecureRandom.uuid }
    let(:study) { create(:v2_study, name: 'Provided Study', uuid: study_uuid) }

    # project
    let(:project_uuid) { SecureRandom.uuid }
    let(:project) { create(:v2_project, name: 'Provided Project', uuid: project_uuid) }

    describe 'first aliquot' do
      let(:first_aliquot) { subject.wells.first.aliquots.first }

      it 'should be a version 2 aliquot' do
        expect(first_aliquot.class).to eq(Sequencescape::Api::V2::Aliquot)
      end

      it 'should have a valid study' do
        expect(first_aliquot.study).to be_kind_of(Sequencescape::Api::V2::Study)
      end
      it 'should have a valid study uuid' do
        expect(first_aliquot.study.uuid).to eq(study_uuid)
      end
      it 'should have a valid study name' do
        expect(first_aliquot.study.name).to eq('Provided Study')
      end

      it 'should have a valid project' do
        expect(first_aliquot.project).to be_kind_of(Sequencescape::Api::V2::Project)
      end
      it 'should have a valid project uuid' do
        expect(first_aliquot.project.uuid).to eq(project_uuid)
      end
      it 'should have a valid project name' do
        expect(first_aliquot.project.name).to eq('Provided Project')
      end
    end
  end
end
