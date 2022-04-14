# frozen_string_literal: true

require 'rails_helper'
require './app/controllers/qc_files_controller'

RSpec.describe QcFilesController, type: :controller do
  has_a_working_api

  describe '#show' do
    let(:file_uuid) { 'file-uuid' }
    let(:filename) { 'my_holiday.jpg' }

    before do
      stub_api_get(file_uuid, body: json(:qc_file, uuid: file_uuid, filename: filename))
      stub_request(:get, api_url_for(file_uuid))
        .with(headers: { 'Accept' => 'sequencescape/qc_file' })
        .to_return(
          body: 'example file content',
          headers: {
            'Content-Disposition' => "attachment; filename=\"#{filename}\""
          }
        )
    end

    it 'returns a file' do
      get :show, params: { id: file_uuid, limber_plate_id: 'plate-uuid' }
      expect(response.body).to eq('example file content')
      expect(response.get_header('Content-Disposition')).to include(filename)
    end
  end

  describe '#create' do
    let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }
    let(:file_content) do
      content = file.read
      file.rewind
      content
    end
    let(:plate_uuid) { 'plate-uuid' }

    let(:stub_post) do
      stub_request(:post, api_url_for(plate_uuid, 'qc_files'))
        .with(
          body: file_content,
          headers: {
            'Content-Type' => 'sequencescape/qc_file',
            'Content-Disposition' => 'form-data; filename="test_file.txt"'
          }
        )
        .to_return(
          status: 201,
          body: json(:qc_file, filename: 'test_file.txt'),
          headers: {
            'content-type' => 'application/json'
          }
        )
    end

    before do
      stub_api_get('plate-uuid', body: json(:plate, uuid: plate_uuid, qc_files_actions: %w[read create]))
      stub_post
    end

    it 'posts the file to the appropriate labware' do
      post :create, params: { qc_file: file, limber_plate_id: plate_uuid }
      expect(stub_post).to have_been_made.once
      expect(flash.notice).to eq('Your file has been uploaded and is available from the file tab')
    end
  end

  describe '#index' do
    let(:plate_uuid) { 'plate-uuid' }

    before do
      stub_api_get(plate_uuid, body: json(:plate, uuid: plate_uuid, qc_files_count: 3))
      stub_api_get(plate_uuid, 'qc_files', body: json(:qc_files_collection, size: 3))
    end

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
      get :index, params: { limber_plate_id: plate_uuid }, format: 'json'
      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end
end
