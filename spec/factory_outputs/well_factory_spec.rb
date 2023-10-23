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

RSpec.describe 'v2_well' do
  subject { create(:v2_well, location: 'A1', aliquots: [source_aliquot1_s1]) }

  # samples
  let(:sample1_uuid) { SecureRandom.uuid }
  let(:sample1) { create(:v2_sample, name: 'Sample1', uuid: sample1_uuid) }

  # source aliquots
  let(:source_aliquot1_s1) { create(:v2_aliquot, sample: sample1) }

  describe 'first aliquot' do
    let(:first_well_aliquot) { subject.aliquots.first }
    it 'should be a version 2 aliquot' do
      expect(first_well_aliquot.class).to eq(Sequencescape::Api::V2::Aliquot)
    end
    it 'should have a valid study' do
      expect(first_well_aliquot.study).to be_kind_of(Sequencescape::Api::V2::Study)
    end

    it 'should have a valid study type' do
      expect(first_well_aliquot.study.type).to eq('studies')
    end
    it 'should have a valid study id' do
      expect(first_well_aliquot.study.id).to be_kind_of(String)
      expect(first_well_aliquot.study.id).to match(/\d+/)
    end
    it 'should have a valid study uuid' do
      expect(first_well_aliquot.study.uuid).to be_kind_of(String)
      expect(first_well_aliquot.study.uuid).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
    it 'should have a valid study name' do
      expect(first_well_aliquot.study.name).to eq('Test Aliquot Study')
    end

    it 'should not have weird shadow attributes' do
      expect(first_well_aliquot.attributes).to_not include('study')
      expect(first_well_aliquot['study']).to be_nil
    end

    it 'should have relationships' do
      expect(first_well_aliquot.relationships).to be_kind_of(JsonApiClient::Relationships::Relations)
    end

    it 'should have a valid study relationship' do
      expect(first_well_aliquot.relationships.study).to be_kind_of(Hash)
    end

    it 'should have valid study relationship data' do
      expect(first_well_aliquot.relationships.study['data']).to be_kind_of(Hash)
    end
  end
end
