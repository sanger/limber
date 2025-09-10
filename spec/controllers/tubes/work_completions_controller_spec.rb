# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tubes::WorkCompletionsController, type: :controller do
  describe '#create' do
    has_a_working_api

    let(:tube_uuid) { SecureRandom.uuid }
    let(:user_uuid) { SecureRandom.uuid }
    let(:tube) { create(:v2_tube, uuid: tube_uuid) }
    let(:work_completions_attributes) { [{ target_uuid: tube_uuid, user_uuid: user_uuid, submission_uuids: [] }] }

    it 'creates work_completion' do
      stub_v2_tube(tube, custom_query: [:tube_for_completion, tube.uuid])
      expect_work_completion_creation

      post :create, params: { tube_id: tube_uuid }, session: { user_uuid: }
      expect(response).to redirect_to(tube_path(tube_uuid))
      expect(flash.notice).to eq(['Requests have been passed'])
    end
  end
end
