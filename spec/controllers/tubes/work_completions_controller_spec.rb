# frozen_string_literal: true

require 'rails_helper'

describe Tubes::WorkCompletionsController, type: :controller do
  describe '#create' do
    has_a_working_api

    let(:tube_uuid) { SecureRandom.uuid }
    let(:user_uuid) { SecureRandom.uuid }
    let(:example_tube) { json :tube, uuid: tube_uuid }
    let(:work_completion_request) do
      { 'work_completion' => { target: tube_uuid, submissions: [], user: user_uuid } }
    end

    let(:work_completion) { json :work_completion }

    let!(:tube_get) { stub_api_get(tube_uuid, body: example_tube) }
    let!(:work_completion_creation) { stub_api_post('work_completions', payload: work_completion_request, body: work_completion) }

    it 'creates work_completion' do
      post :create, params: { limber_tube_id: tube_uuid }, session: { user_uuid: user_uuid }
      expect(response).to redirect_to(limber_tube_path(tube_uuid))
      expect(tube_get).to have_been_made
      expect(work_completion_creation).to have_been_made.once
      assert_equal ['Requests have been passed'], flash.notice
    end
  end
end
