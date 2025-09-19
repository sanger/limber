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
end
