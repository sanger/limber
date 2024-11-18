# frozen_string_literal: true

require 'rails_helper'

class TestPoolingClass
  include LabwareCreators::DonorPoolingCalculator
end

RSpec.describe LabwareCreators::DonorPoolingCalculator do
  let(:test_pooling_class) { TestPoolingClass.new }
  let(:pool) { [source_well1] }
  let(:source_well1) { create :v2_well, aliquots: [aliquot1] }
  let(:aliquot1) { create :v2_aliquot, request: request1 }
  let(:request1) { create :scrna_customer_request, request_metadata: request_metadata1 }
  let(:request_metadata1) { create :v2_request_metadata, cells_per_chip_well: }
  let(:cells_per_chip_well) { 1000 }

  describe '#number_of_cells_per_chip_well_from_request' do
    context 'when the request metadata is nil' do
      let(:request_metadata1) { nil }

      it 'returns nil' do
        expect do
          test_pooling_class.send(:number_of_cells_per_chip_well_from_request, pool)
        end.to raise_error StandardError,
                    'No request found for source well at A1, cannot fetch ' \
                      'cells per chip well metadata for full allowance calculations'
      end
    end

    context 'when there is a single source well with request_metadata' do
      it 'returns the number of cells per chip well' do
        expect(test_pooling_class.send(:number_of_cells_per_chip_well_from_request, pool)).to eq(1000)
      end
    end

    context 'when there are multiple source wells' do
      let(:source_well2) { create :v2_well, aliquots: [aliquot2] }
      let(:aliquot2) { create :v2_aliquot, request: request2 }
      let(:request2) { create :scrna_customer_request, request_metadata: request_metadata2 }
      let(:request_metadata2) { create :v2_request_metadata, cells_per_chip_well: }
      let(:pool) { [source_well1, source_well2] }

      it 'returns the number of cells per chip well from the first source well' do
        expect(test_pooling_class.send(:number_of_cells_per_chip_well_from_request, pool)).to eq(1000)
      end
    end

    context 'when there are multiple aliquots in a source well' do
      let(:aliquot2) { create :v2_aliquot, request: request2 }
      let(:request2) { create :scrna_customer_request, request_metadata: request_metadata2 }
      let(:request_metadata2) { create :v2_request_metadata, cells_per_chip_well: }
      let(:source_well) { create :v2_well, aliquots: [aliquot1, aliquot2] }

      it 'returns the number of cells per chip well from the first aliquot' do
        expect(test_pooling_class.send(:number_of_cells_per_chip_well_from_request, pool)).to eq(1000)
      end
    end
  end
end
