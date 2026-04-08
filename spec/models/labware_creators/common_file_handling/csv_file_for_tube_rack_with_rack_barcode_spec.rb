# frozen_string_literal: true

# See also tests for CsvFileForTubeRack
# This class is a subclass of CsvFileForTubeRack
RSpec.describe LabwareCreators::CommonFileHandling::CsvFileForTubeRackWithRackBarcode, with: :uploader do
  subject { described_class.new(file) }

  # there should be only one rack barcode in the file and it should be the same for all rows
  context 'A file with inconsistant rack barcodes' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/common_file_handling/' \
        'tube_rack_with_rack_barcode/tube_rack_scan_with_different_rack_barcodes.csv',
        'sequencescape/qc_file'
      )
    end

    describe '#valid?' do
      it 'is invalid' do
        expect(subject.valid?).to be false
      end

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include(
          'should not contain different rack barcodes (FX12345678,FX23838838)'
        )
      end
    end
  end
end
