# frozen_string_literal: true
require 'rails_helper'
require './app/controllers/work_completion_controller'

describe WorkCompletionController, type: :controller do
  describe '#create' do
    has_a_working_api

    let(:plate_uuid) { SecureRandom.uuid }
    let(:user_uuid) { SecureRandom.uuid }
    let(:example_plate)  { json :stock_plate, uuid: plate_uuid, pool_sizes: [8, 8] }
    let(:work_completion_request) do
      { 'work_completion' => { target: plate_uuid, submissions: ['pool-1-uuid', 'pool-2-uuid'], user: user_uuid } }
    end

    let(:work_completion) { json :work_completion }

    it 'creates work_completion' do
      # # We get the actual plate
      plate_get = stub_request(:get, 'http://example.com:3000/' + plate_uuid)
        .to_return(status: 200, body: example_plate, headers: { 'content-type' => 'application/json' })

      work_completion_creation = stub_request(:post, 'http://example.com:3000/work_completions')
        .with(body: work_completion_request, headers: { content_type: 'application/json' })
        .to_return(status: 201, body: work_completion, headers: { 'content-type' => 'application/json' })

      post :create, params: { limber_plate_id: plate_uuid }, session: { user_uuid: user_uuid }
      expect(response).to redirect_to(limber_plate_path(plate_uuid))
      expect(plate_get).to have_been_made
      expect(work_completion_creation).to have_been_made.once
      assert_equal 'Requests have been passed', flash.notice
    end
  end
end
