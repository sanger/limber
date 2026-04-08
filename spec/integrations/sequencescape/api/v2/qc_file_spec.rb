# frozen_string_literal: true

RSpec.describe Sequencescape::Api::V2::QcFile do
  describe '.sanitise_contents' do
    let(:result) { described_class.sanitise_contents(test_string) }

    context 'with invalid UTF-8 bytes' do
      let(:test_string) { "\xC3\x28".b } # invalid UTF-8 sequence

      it 'raises JSON::GeneratorError' do
        expect { result }.to raise_error(JSON::GeneratorError, /Invalid UTF-8/)
      end
    end

    context 'with valid UTF-8 bytes' do
      let(:test_string) { 'valid UTF-8 string'.b }

      it 'returns UTF-8 encoded string' do
        expect(result.encoding.name).to eq('UTF-8')
      end

      it 'does not modify the input' do
        expect(result).to eq('valid UTF-8 string')
      end
    end
  end
end
