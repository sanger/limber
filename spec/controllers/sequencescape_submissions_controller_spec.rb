# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeSubmissionsController, type: :controller do
  describe '#create' do
    let(:user_uuid) { SecureRandom.uuid }
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

    let(:submissions_attributes) do
      [{ attributes: { and_submit: true, order_uuids: ['order-uuid'], user_uuid: user_uuid }, uuid_out: 'sub-uuid' }]
    end

    it 'creates a submission' do
      expect_order_creation
      expect_submission_creation

      post :create, params: request_parameters, session: { user_uuid: }
      expect(flash.notice).to eq(['Your submissions have been made and should be built shortly.'])
    end
  end
end
