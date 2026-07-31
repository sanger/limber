# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::Base do
  describe '.find!' do
    let(:resource_class) { described_class }
    let(:resource) { create(:labware) }
    let(:resource_barcode) { resource.barcode.human }

    context 'when the resource exists' do
      before do
        allow(resource_class).to receive(:find).with(hash_including(barcode: resource_barcode)).and_return([resource])
      end

      it 'returns the resource' do
        expect(resource_class.find!(barcode: resource_barcode)).to eq([resource])
      end
    end

    context 'when the resource does not exist' do
      before do
        allow(resource_class).to receive(:find).with(hash_including(barcode: 'not-a-barcode')).and_return([])
      end

      it 'raises JsonApiClient::Errors::NotFound' do
        expect do
          resource_class.find!(barcode: 'not-a-barcode')
        end.to raise_error(JsonApiClient::Errors::NotFound, 'Resource not found: Resource not found')
      end
    end
  end

  describe 'API key header' do
    it 'sets the X-Sequencescape-Client-Id header from configuration' do
      # The header should be set from connection_options.authorisation
      expected_header_value = Limber::Application.config.api.v2.connection_options.authorisation

      actual_header = described_class.connection.faraday.headers['X-Sequencescape-Client-Id']
      expect(actual_header).to eq(expected_header_value)
    end

    it 'sets the X-Sequencescape-Client-Id header to the test authorization value' do
      # In test environment, this should be 'test'
      expect(described_class.connection.faraday.headers['X-Sequencescape-Client-Id']).to eq('test')
    end
  end
end
