# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeSubmissionsController, type: :controller do
  describe '#create' do
    has_a_working_api

    let(:user_uuid) { SecureRandom.uuid }
    let(:example_plate) { create :v2_plate, uuid: plate_uuid, pool_sizes: [8, 8], include_submissions: true }
    let(:request_options) do
      {
        'library_type' => 'Sanger_tailed_artic_v1_96',
        'read_length' => '150',
        'fragment_size_required_from' => '50',
        'fragment_size_required_to' => '800',
        'primer_panel_name' => 'nCoV-2019/V4.1alt'
      }
    end
    let(:template_uuid) { SecureRandom.uuid }
    let(:asset_uuids) { %w[f5bba76c-2979-11eb-a652-acde48001122 f5bba91a-2979-11eb-a652-acde48001122] }
    let(:request_parameters) do
      {
        'sequencescape_submission' => {
          'request_options' => request_options,
          'template_uuid' => template_uuid,
          'asset_groups' => {
            '0' => {
              'assets' => asset_uuids
            }
          }
        }
      }
    end

    let(:orders_attributes) do
      [
        {
          attributes: {
            submission_template_uuid: template_uuid,
            submission_template_attributes: {
              'asset_uuids' => asset_uuids,
              :request_options => request_options,
              :user_uuid => user_uuid
            }
          },
          uuid_out: 'order-uuid'
        }
      ]
    end

    let!(:submission_request) do
      stub_api_post(
        'submissions',
        payload: {
          submission: {
            orders: ['order-uuid'],
            user: user_uuid
          }
        },
        body: json(:submission, uuid: 'sub-uuid', orders: [{ uuid: 'order-uuid' }])
      )
    end

    let!(:submission_submit) { stub_api_post('sub-uuid', 'submit') }

    it 'creates a submission' do
      expect_order_creation

      post :create, params: request_parameters, session: { user_uuid: }
      expect(submission_request).to have_been_made.once
      expect(submission_submit).to have_been_made.once
      assert_equal ['Your submissions have been made and should be built shortly.'], flash.notice
    end
  end
end
