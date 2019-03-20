# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plates::WorkCompletionsController, type: :controller do
  describe '#create' do
    has_a_working_api

    let(:plate_uuid) { SecureRandom.uuid }
    let(:user_uuid) { SecureRandom.uuid }
    let(:example_plate) { create :v2_plate, uuid: plate_uuid, pool_sizes: [8, 8], include_submissions: true }
    let(:work_completion_request) do
      { 'work_completion' => { target: plate_uuid, submissions: ['pool-1-uuid', 'pool-2-uuid'], user: user_uuid } }
    end

    let(:work_completion) { json :work_completion }

    let!(:plate_get) do
      stub_v2_plate(example_plate, stub_search: false, custom_query: [:plate_for_completion, example_plate.uuid])
    end
    let!(:work_completion_creation) { stub_api_post('work_completions', payload: work_completion_request, body: work_completion) }

    it 'creates work_completion' do
      post :create, params: { limber_plate_id: plate_uuid }, session: { user_uuid: user_uuid }
      expect(response).to redirect_to(limber_plate_path(plate_uuid))
      expect(work_completion_creation).to have_been_made.once
      assert_equal ['Requests have been passed'], flash.notice
    end
  end
end
