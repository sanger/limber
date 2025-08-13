# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::Request do
  subject(:request) { create :library_request_with_poly_metadata }

  describe '#poly_metadata' do
    # In reality, we will not pass metadatable into the initializer as this factory makes it appear.
    # To use this we found we had to do these steps:
    # 1. select the metadatable object instance (e.g. a request here) e.g.
    #    r = Sequencescape::Api::V2::Request.find(1234).first
    # 2. create the new poly metadatum instance, e.g.
    #    pm1 = Sequencescape::Api::V2::PolyMetadatum.new(key: 'test_key', value: 'test_value')
    # 3. then set the metadatable on the new poly metadatum, e.g.
    #    pm1.relationships.metadatable = r
    # 4. then finally save the poly metadatum to persist it, i.e.
    #    pm1.save
    let(:test_poly_metadatum) { build :poly_metadatum, metadatable: request, key: 'key1', value: 'value1' }

    before do
      # stub_api_v2_save just checks something is being sent, not specifically what
      stub_api_v2_save('PolyMetadatum')
    end

    context 'when we want to create poly metadata on a request' do
      it 'triggers save on the poly metadatum via api v2' do
        expect(test_poly_metadatum.save).to be true
      end
    end

    context 'when we want to update existing poly metadata on a request' do
      it 'triggers an update on the request via api v2' do
        expect(test_poly_metadatum.save).to be true
      end

      it 'updates the poly metadata key and value' do
        expect(test_poly_metadatum.update(value: 'value2')).to be true
      end
    end
  end
end
