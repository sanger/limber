RSpec.describe Sequencescape::Api::V2::QcFile do
  describe '.sanitize_contents' do
    it 'raises JSON::GeneratorError for invalid UTF-8 bytes' do
      bad_bytes = "\xC3\x28".b  # invalid UTF-8 sequence
      expect {
        described_class.sanitize_contents(bad_bytes)
      }.to raise_error(JSON::GeneratorError, /Invalid UTF-8/)
    end

    it 'returns UTF-8 encoded string for valid input' do
      good_bytes = "valid UTF-8 string".b
      result = described_class.sanitize_contents(good_bytes)
      expect(result.encoding.name).to eq('UTF-8')
      expect(result).to eq("valid UTF-8 string")
    end
  end
end
