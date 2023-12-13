# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::Request do
  subject(:request) { described_class.new }

  describe '#poly_metadata' do
    # let(:req_poly_metadata) { request.poly_metadata }
    let(:test_poly_metadatum) { build_stubbed :v2_poly_metadatum }

    context 'when we want to create poly metadata on a request' do
      it 'creates the new poly metadatum' do
        expect(request.poly_metadata).to be_empty
        request.poly_metadata << test_poly_metadatum
        expect(request.poly_metadata).to include(test_poly_metadatum)
      end
    end

    context 'when we want to select the poly metadata for a request' do
      it 'returns the poly metadata for the request' do
        request.poly_metadata << test_poly_metadatum
        expect(request.poly_metadata).to include(test_poly_metadatum)
      end
    end

    context 'when we want to update poly metadata on a request' do
      it 'updates the poly metadata for the request' do
        request.poly_metadata << test_poly_metadatum
        expect(request.poly_metadata).to include(test_poly_metadatum)
        test_poly_metadatum.key = 'new_key'
        test_poly_metadatum.value = 'new_value'
        expect(request.poly_metadata).to include(test_poly_metadatum)
      end
    end

    context 'when we want to delete poly metadata on a request' do
      it 'deletes the poly metadata for the request' do
        request.poly_metadata << test_poly_metadatum
        expect(request.poly_metadata).to include(test_poly_metadatum)
        request.poly_metadata.delete(test_poly_metadatum)
        expect(request.poly_metadata).not_to include(test_poly_metadatum)
      end
    end
  end
end
