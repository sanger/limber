# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeSubmission do
  has_a_working_api

  subject { SequencescapeSubmission.new(api: api, assets: assets, template_uuid: template_uuid, request_options: request_options, user: user_uuid) }

  let(:assets) { ['asset-uuid'] }
  let(:template_uuid) { 'template-uuid' }
  let(:request_options) { { read_length: 150 } }
  let(:user_uuid) { 'user-uuid' }
  let(:user) { create :user, uuid: user_uuid }

  describe '#save' do
    let!(:order_request) do
      stub_api_get(template_uuid, body: json(:submission_template, uuid: template_uuid))
      stub_api_post(template_uuid, 'orders',
                    payload: { order: {
                      assets: assets,
                      request_options: request_options,
                      user: user_uuid
                    } },
                    body: '{"order":{"uuid":"order-uuid"}}')
    end

    let!(:submission_request) do
      stub_api_post('submissions',
                    payload: { submission: { orders: ['order-uuid'], user: user_uuid } },
                    body:  json(:submission, uuid: 'sub-uuid', orders: [{ uuid: 'order-uuid' }]))
    end

    let!(:submission_submit) do
      stub_api_post('sub-uuid', 'submit')
    end

    it 'generates a submission' do
      expect(subject.save).to be_truthy
      expect(order_request).to have_been_made.once
      expect(submission_request).to have_been_made.once
      expect(submission_submit).to have_been_made.once
    end
  end
end
