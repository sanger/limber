# frozen_string_literal: true

require 'rails_helper'

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
