# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Plates::WorkCompletionsController, type: :controller do
  describe '#create' do
    let(:plate_uuid) { SecureRandom.uuid }
    let(:user_uuid) { SecureRandom.uuid }
    let(:example_plate) { create :plate, uuid: plate_uuid, pool_sizes: [8, 8], include_submissions: true }
    let(:work_completions_attributes) do
      [{ target_uuid: plate_uuid, user_uuid: user_uuid, submission_uuids: %w[pool-1-uuid pool-2-uuid] }]
    end

    let!(:plate_get) do
      stub_plate(example_plate, stub_search: false, custom_query: [:plate_for_completion, example_plate.uuid])
    end

    it 'creates work_completion' do
      expect_work_completion_creation

      post :create, params: { plate_id: plate_uuid }, session: { user_uuid: }
      expect(response).to redirect_to(plate_path(plate_uuid))
      expect(flash.notice).to eq(['Requests have been passed'])
    end
  end
end
