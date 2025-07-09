# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/qc_files_controller'

RSpec.describe QcFilesController, type: :controller do
  has_a_working_api

  let(:plate) { create(:v2_plate, uuid: 'plate-uuid', qc_files_count: 3) }

  before { stub_v2_plate(plate, stub_search: false) }

  describe '#show' do
    let(:qc_file) { create(:qc_file, uuid: 'file-uuid', filename: 'important_qc_data.csv') }

    before { stub_v2_qc_file(qc_file) }

    it 'returns a file' do
      get :show, params: { id: qc_file.uuid, plate_id: plate.uuid }

      expect(response.body).to eq('example,file,content')
      expect(response.get_header('Content-Disposition')).to include(qc_file.filename)
    end
  end

  describe '#create' do
    let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

    let(:file_contents) do
      content = file.read
      file.rewind
      content
    end

    let(:qc_files_attributes) do
      [
        {
          contents: file_contents,
          filename: 'test_file.txt',
          relationships: {
            labware: {
              data: {
                id: plate.id,
                type: 'labware'
              }
            }
          }
        }
      ]
    end

    it 'posts the file to the appropriate labware' do
      expect_qc_file_creation

      post :create, params: { qc_file: file, plate_id: plate.uuid }

      expect(flash.notice).to eq('Your file has been uploaded and is available from the file tab')
    end
  end

  describe '#index' do
    let(:expected_response) do
      {
        'qc_files' => [
          {
            'filename' => 'file0.txt',
            'size' => 123,
            'uuid' => 'example-file-uuid-0',
            'created' => 'June 29, 2017 09:31'
          },
          {
            'filename' => 'file1.txt',
            'size' => 123,
            'uuid' => 'example-file-uuid-1',
            'created' => 'June 29, 2017 09:31'
          },
          {
            'filename' => 'file2.txt',
            'size' => 123,
            'uuid' => 'example-file-uuid-2',
            'created' => 'June 29, 2017 09:31'
          }
        ]
      }
    end

    it 'returns the qc files as json' do
      get :index, params: { plate_id: plate.uuid }, format: 'json'
      expect(response.parsed_body).to eq(expected_response)
    end
  end
end
