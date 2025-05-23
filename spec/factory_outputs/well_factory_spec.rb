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

  it 'matches the expected json' do
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

  it 'matches the expected json' do
    expect(JSON.parse(subject)).to include_json(JSON.parse(json_content))
  end
end

RSpec.describe 'v2_well' do
  # samples
  let(:sample) { create(:v2_sample) }

  context 'with default study' do
    subject { create(:v2_well, location: 'A1', aliquots: [source_aliquot]) }

    # source aliquots
    let(:source_aliquot) { create(:v2_aliquot, sample:) }

    describe 'first aliquot' do
      let(:first_well_aliquot) { subject.aliquots.first }

      let(:study_id) { first_well_aliquot.relationships.study.dig(:data, :id) }
      let(:project_id) { first_well_aliquot.relationships.project.dig(:data, :id) }

      it 'is a version 2 aliquot' do
        expect(first_well_aliquot.class).to eq(Sequencescape::Api::V2::Aliquot)
      end

      it 'has a valid sample' do
        expect(first_well_aliquot.sample).to be_a(Sequencescape::Api::V2::Sample)
      end

      it 'has a valid study' do
        expect(first_well_aliquot.study).to be_a(Sequencescape::Api::V2::Study)
      end

      it 'has a valid study type' do
        expect(first_well_aliquot.study.type).to eq('studies')
      end

      it 'has a valid study id' do
        expect(first_well_aliquot.study.id).to be_a(String)
        expect(first_well_aliquot.study.id).to match(/\d+/)
      end

      it 'has a valid study uuid' do
        expect(first_well_aliquot.study.uuid).to be_a(String)
        expect(first_well_aliquot.study.uuid).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      end

      it 'has a valid study name' do
        expect(first_well_aliquot.study.name).to eq('Test Aliquot Study')
      end

      it 'does not have weird shadow attributes' do
        expect(first_well_aliquot.attributes).not_to include('study')
        expect(first_well_aliquot['study']).to be_nil
      end

      it 'has relationships' do
        expect(first_well_aliquot.relationships).to be_a(JsonApiClient::Relationships::Relations)
      end

      it 'has a valid study relationship' do
        expect(first_well_aliquot.relationships.study).to be_a(Hash)
      end

      it 'has valid study relationship data' do
        expect(first_well_aliquot.relationships.study['data']).to be_a(Hash)
      end

      it 'orders groups' do
        expect(first_well_aliquot.order_group).to eq([study_id, project_id])
      end
    end
  end

  context 'with specified study and project at aliquot level' do
    subject { create(:v2_well, location: 'A1', aliquots: [source_aliquot]) }

    let(:first_aliquot) { subject.aliquots.first }

    # source aliquots
    let(:source_aliquot) { create(:v2_aliquot, sample:, study:, project:) }

    # study
    let(:study_uuid) { SecureRandom.uuid }
    let(:study) { create(:v2_study, name: 'Provided Study', uuid: study_uuid) }

    # project
    let(:project_uuid) { SecureRandom.uuid }
    let(:project) { create(:v2_project, name: 'Provided Project', uuid: project_uuid) }

    describe 'first aliquot' do
      it 'is a version 2 aliquot' do
        expect(first_aliquot.class).to eq(Sequencescape::Api::V2::Aliquot)
      end

      it 'has a valid study' do
        expect(first_aliquot.study).to be_a(Sequencescape::Api::V2::Study)
      end

      it 'has a valid study type' do
        expect(first_aliquot.study.type).to eq('studies')
      end

      it 'has a valid study uuid' do
        expect(first_aliquot.study.uuid).to eq(study_uuid)
      end

      it 'has a valid study name' do
        expect(first_aliquot.study.name).to eq('Provided Study')
      end

      it 'has a valid project' do
        expect(first_aliquot.project).to be_a(Sequencescape::Api::V2::Project)
      end

      it 'has a valid project type' do
        expect(first_aliquot.project.type).to eq('projects')
      end

      it 'has a valid project uuid' do
        expect(first_aliquot.project.uuid).to eq(project_uuid)
      end

      it 'has a valid project name' do
        expect(first_aliquot.project.name).to eq('Provided Project')
      end
    end
  end

  context 'with specified study and project at well level' do
    subject { create(:v2_well, study:, project:) }

    let(:first_aliquot) { subject.aliquots.first }

    # study
    let(:study_uuid) { SecureRandom.uuid }
    let(:study) { create(:v2_study, name: 'Provided Study', uuid: study_uuid) }

    # project
    let(:project_uuid) { SecureRandom.uuid }
    let(:project) { create(:v2_project, name: 'Provided Project', uuid: project_uuid) }

    describe 'first aliquot' do
      it 'is a version 2 aliquot' do
        expect(first_aliquot.class).to eq(Sequencescape::Api::V2::Aliquot)
      end

      it 'has a valid study' do
        expect(first_aliquot.study).to be_a(Sequencescape::Api::V2::Study)
      end

      it 'has a valid study uuid' do
        expect(first_aliquot.study.uuid).to eq(study_uuid)
      end

      it 'has a valid study name' do
        expect(first_aliquot.study.name).to eq('Provided Study')
      end

      it 'has a valid project' do
        expect(first_aliquot.project).to be_a(Sequencescape::Api::V2::Project)
      end

      it 'has a valid project uuid' do
        expect(first_aliquot.project.uuid).to eq(project_uuid)
      end

      it 'has a valid project name' do
        expect(first_aliquot.project.name).to eq('Provided Project')
      end
    end
  end
end
