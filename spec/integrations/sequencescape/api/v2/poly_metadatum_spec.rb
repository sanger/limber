# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::PolyMetadatum do
  let(:aliquot) { create(:v2_aliquot) }

  describe '.as_bulk_payload' do
    it 'returns a JSON:API compliant bulk payload' do
      metadata_array = [
        { key: 'vol to pool', value: '32.453', metadatable: aliquot },
        { key: 'barcode', value: 'Z0001', metadatable: aliquot }
      ]

      payload = described_class.as_bulk_payload(metadata_array)

      expect(payload).to eq(
        data: [
          {
            type: 'poly_metadata',
            attributes: { key: 'vol to pool', value: '32.453' },
            relationships: {
              metadatable: { data: { type: aliquot.type, id: aliquot.id } }
            }
          },
          {
            type: 'poly_metadata',
            attributes: { key: 'barcode', value: 'Z0001' },
            relationships: {
              metadatable: { data: { type: aliquot.type, id: aliquot.id } }
            }
          }
        ]
      )
    end
  end

  describe '.bulk_create' do
    let(:payload) do
      described_class.as_bulk_payload([
                                        { key: 'test_key', value: 'test_value', metadatable: aliquot }
                                      ])
    end

    it 'sends a POST request to the bulk_create endpoint' do
      stub_request(:post, '/poly_metadata/bulk_create')
        .to_return(
          status: 201,
          body: { data: [{ id: '1', type: 'poly_metadata',
                           attributes: { key: 'test_key', value: 'test_value' } }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      described_class.bulk_create(payload)

      expect(WebMock).to have_requested(:post, '/poly_metadata/bulk_create')
        .with(body: payload.to_json)
    end
  end
end
