# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tubes::WorkCompletionsController, type: :controller do
  describe '#create' do
    has_a_working_api

    let(:tube_uuid) { SecureRandom.uuid }
    let(:user_uuid) { SecureRandom.uuid }
    let(:tube) { create(:v2_tube, uuid: tube_uuid) }
    let(:work_completion_request) { { 'work_completion' => { target: tube_uuid, submissions: [], user: user_uuid } } }

    let(:work_completion) { json :work_completion }

    let!(:work_completion_creation) do
      stub_api_post('work_completions', payload: work_completion_request, body: work_completion)
    end

    it 'creates work_completion' do
      stub_v2_tube(tube, custom_query: [:tube_for_completion, tube.uuid])

      post :create, params: { limber_tube_id: tube_uuid }, session: { user_uuid: }
      expect(response).to redirect_to(limber_tube_path(tube_uuid))
      expect(work_completion_creation).to have_been_made.once
      expect(flash.notice).to eq(['Requests have been passed'])
    end
  end
end
