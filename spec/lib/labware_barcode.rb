# frozen_string_literal: true

RSpec.describe LabwareBarcode do
  shared_examples 'a labware barcode' do |input|
    let(:labware_barcode) { described_class.new(**input) }

    describe '#=~' do
      it 'matches equivalent barcodes' do
        equivalent_barcodes.each { |equivalent_barcode| expect(labware_barcode =~ equivalent_barcode).to be true }
      end

      it 'rejects non-equivalent barcodes' do
        non_equivalent_barcodes.each do |non_equivalent_barcode|
          expect(labware_barcode =~ non_equivalent_barcode).to be false
        end
      end
    end
  end

  context 'with a code39 Sanger Barcode (DN) format' do
    let(:equivalent_barcodes) { %w[1220000123724 DN123H] }
    let(:non_equivalent_barcodes) { %w[1220000124738 DN124I WD123Q 123 HT-22335] }

    it_behaves_like 'a labware barcode', { ean13: '1220000123724', machine: 'DN123H', human: 'DN123H' }
  end

  context 'with a ean13 Sanger Barcode (DN) format' do
    let(:equivalent_barcodes) { %w[1220000123724 DN123H] }
    let(:non_equivalent_barcodes) { %w[1220000124738 DN124I WD123Q 123 HT-22335] }

    it_behaves_like 'a labware barcode', { ean13: '1220000123724', machine: '1220000123724', human: 'DN123H' }
  end

  context 'with a non Sanger Barcode format' do
    let(:equivalent_barcodes) { ['HT-111123'] }
    let(:non_equivalent_barcodes) { %w[1220000124738 DN124I WD123Q 123 HT-22335 DN111123] }

    it_behaves_like 'a labware barcode', { ean13: nil, machine: 'HT-111123', human: 'HT-111123' }
  end
end
