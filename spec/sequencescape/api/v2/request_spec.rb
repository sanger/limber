# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::Request do
  subject(:request) { create :library_request_with_poly_metadata }

  describe '#poly_metadata' do
    # In reality, we will not pass metadatable into the initializer as this factory makes it appear.
    # Instead we would do this in sequence:
    # 1. select our metadatable request. e.g.
    #    r = Sequencescape::Api::V2::Request.find(11180).first
    # 2. create the new poly metadatum, e.g.
    #    pm1 = Sequencescape::Api::V2::PolyMetadatum.new(key: 'test_key', value: 'test_value')
    # 3. set the metadatable on the poly metadatum, e.g.
    #    pm1.relationships.metadatable = r
    # 4. save the poly metadatum, e.g.
    #    pm1.save
    # If we set the metadatable into the initializer, the save fails as the metadatable is treated as
    # an attribute and not a relationship.
    let(:test_poly_metadatum) { build :poly_metadatum, metadatable: request, key: 'key1', value: 'value1' }

    # stub_api_v2_save just checks something is being sent, not specifically what
    let!(:api_v2_saves_poly_metadata) { stub_api_v2_save('PolyMetadatum') }

    context 'when we want to create poly metadata on a request' do
      it 'triggers save on the poly metadatum via api v2' do
        expect(test_poly_metadatum.save).to eq true
      end
    end

    context 'when we want to update existing poly metadata on a request' do
      it 'triggers an update on the request via api v2' do
        expect(test_poly_metadatum.save).to eq true
        expect(test_poly_metadatum.update(value: 'value2')).to eq true
      end
    end
  end
end
