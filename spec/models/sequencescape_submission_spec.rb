# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeSubmission do
  has_a_working_api

  subject(:submission) do
    described_class.new(attributes)
  end

  let(:assets) { ['asset-uuid'] }
  let(:template_uuid) { 'template-uuid' }
  let(:request_options) { { read_length: 150 } }
  let(:user_uuid) { 'user-uuid' }
  let(:attributes) do
    {
      api: api, assets: assets, template_uuid: template_uuid,
      request_options: request_options, user: user_uuid
    }
  end

  describe '#template_uuid' do
    context 'when set directly' do
      it 'returns the set uuid' do
        expect(submission.template_uuid).to eq(template_uuid)
      end
    end

    context 'when set via template_name' do
      let(:template_name) { 'Submission template' }
      let(:attributes) do
        {
          api: api, assets: assets, template_uuid: template_uuid,
          request_options: request_options, user: user_uuid
        }
      end

      before { Settings.submission_templates = { template_name => template_uuid } }

      it 'looks up the uuid' do
        expect(submission.template_uuid).to eq(template_uuid)
      end
    end
  end

  describe '#extra_barcodes_list' do
    let(:attributes) do
      {
        api: api, assets: assets, template_uuid: template_uuid,
        request_options: request_options, user: user_uuid
      }
    end

    it 'splits by whitespace' do
      obj = described_class.new(attributes.merge(extra_barcodes: '1234 5678'))
      expect(obj.extra_barcodes_list).to eq(%w[1234 5678])
    end
    it 'splits by new line' do
      obj = described_class.new(attributes.merge(extra_barcodes: "1234\n5678"))
      expect(obj.extra_barcodes_list).to eq(%w[1234 5678])
    end
  end

  describe '#extra_plates' do
    let(:attributes) do
      {
        api: api, assets: assets, template_uuid: template_uuid,
        request_options: request_options, user: user_uuid
      }
    end

    let(:plate) { create :v2_plate }
    let(:obj) { described_class.new(attributes.merge(extra_barcodes: '1234 5678')) }
    it 'raises error if barcodes not found in service' do
      allow(Sequencescape::Api::V2).to receive(:additional_plates_for_presenter).and_return(nil)
      expect { obj.extra_plates }.to raise_error
    end
    it 'returns the data obtained from service' do
      allow(Sequencescape::Api::V2).to receive(:additional_plates_for_presenter).and_return([plate])
      expect(obj.extra_plates).to eq([plate])
    end
  end

  describe '#extra_assets' do
    let(:attributes) do
      {
        api: api, assets: assets, template_uuid: template_uuid,
        request_options: request_options, user: user_uuid
      }
    end

    let(:plate) { create(:passed_plate) }
    let(:plate2) { create(:passed_plate) }
    it 'returns the uuids of the labwares wells' do
      obj = described_class.new(attributes.merge(extra_barcodes: '1234 5678'))
      allow(Sequencescape::Api::V2).to receive(:additional_plates_for_presenter)
        .with(barcode: %w[1234 5678]).and_return([plate, plate2])
      # There are 4 non-empty wells in each labware
      expect(obj.extra_assets.count).to eq(8)
    end
    it 'removes duplicates uuids in the returned list' do
      allow(Sequencescape::Api::V2).to receive(:additional_plates_for_presenter)
        .with(barcode: %w[1234 1234 5678]).and_return([plate, plate, plate2])
      obj = described_class.new(attributes.merge(extra_barcodes: '1234 1234 5678'))
      expect(obj.extra_assets.count).to eq(8)
      expect(obj.extra_assets.uniq.count).to eq(8)
    end
  end

  describe '#asset_groups_for_orders_creation' do
    let(:attributes) do
      {
        api: api, assets: assets, template_uuid: template_uuid,
        request_options: request_options, user: user_uuid
      }
    end

    it 'returns normal asset groups when no extra barcodes provided' do
      obj = described_class.new(attributes)
      expect(obj.asset_groups_for_orders_creation).to eq(obj.asset_groups)
    end
    context 'when extra barcodes provided' do
      let(:plate) { create(:passed_plate) }
      let(:plate2) { create(:passed_plate) }

      before do
        allow(Sequencescape::Api::V2).to receive(:additional_plates_for_presenter)
          .with(barcode: %w[1234 5678]).and_return([plate, plate2])
      end

      it 'returns the current assets plus the extra assets' do
        obj = described_class.new(attributes.merge(extra_barcodes: '1234 5678'))
        expect(obj.asset_groups_for_orders_creation.first[:assets].count).to eq(obj.assets.count + 8)
      end
    end
  end

  describe '#save' do
    context 'with a single asset group' do
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
                      body: json(:submission, uuid: 'sub-uuid', orders: [{ uuid: 'order-uuid' }]))
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

    # When making submissions of plates, we may need to deal with wells
    # associated with different studies. To do this we group them into multiple
    # asset groups.
    context 'with a multiple asset groups' do
      let(:study1_uuid) { SecureRandom.uuid }
      let(:study2_uuid) { SecureRandom.uuid }
      let(:project1_uuid) { SecureRandom.uuid }
      let(:project2_uuid) { SecureRandom.uuid }

      let(:assets2) { ['asset-2-uuid'] }
      let(:attributes) do
        {
          api: api,
          asset_groups: {
            '1' => { assets: assets, study: study1_uuid, project: project1_uuid },
            '2' => { assets: assets2, study: study2_uuid, project: project2_uuid }
          },
          template_uuid: template_uuid,
          request_options: request_options,
          user: user_uuid
        }
      end

      let!(:order_request) do
        stub_api_get(template_uuid, body: json(:submission_template, uuid: template_uuid))
        stub_api_post(template_uuid, 'orders',
                      payload: { order: {
                        study: study1_uuid,
                        project: project1_uuid,
                        assets: assets,
                        request_options: request_options,
                        user: user_uuid
                      } },
                      body: '{"order":{"uuid":"order-uuid"}}')
        stub_api_post(template_uuid, 'orders',
                      payload: { order: {
                        study: study2_uuid,
                        project: project2_uuid,
                        assets: assets2,
                        request_options: request_options,
                        user: user_uuid
                      } },
                      body: '{"order":{"uuid":"order-2-uuid"}}')
      end

      let!(:submission_request) do
        stub_api_post('submissions',
                      payload: { submission: { orders: ['order-uuid', 'order-2-uuid'], user: user_uuid } },
                      body: json(:submission, uuid: 'sub-uuid', orders: [
                                   { uuid: 'order-uuid' }, { uuid: 'order-2-uuid' }
                                 ]))
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
end
