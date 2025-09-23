# frozen_string_literal: true

require 'rails_helper'

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

RSpec.describe 'v2_plate_for_submission' do
  context 'with specified study and project at plate level' do
    subject { create(:v2_plate_for_submission, aliquots_without_requests: 1, study: study, project: project) }

    # study
    let(:study_uuid) { SecureRandom.uuid }
    let(:study) { create(:v2_study, name: 'Provided Study', uuid: study_uuid) }

    # project
    let(:project_uuid) { SecureRandom.uuid }
    let(:project) { create(:v2_project, name: 'Provided Project', uuid: project_uuid) }

    describe 'first aliquot' do
      let(:first_aliquot) { subject.wells.first.aliquots.first }

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
