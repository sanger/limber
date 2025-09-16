# frozen_string_literal: true

RSpec.describe LabwareCreators::CommonFileHandling::CsvFileForTubeRack, with: :uploader do
  subject { described_class.new(file) }

  context 'Valid files' do
    let(:expected_position_details) do
      {
        'A1' => {
          'tube_barcode' => 'AB10000001'
        },
        'B1' => {
          'tube_barcode' => 'AB10000002'
        },
        'C1' => {
          'tube_barcode' => 'AB10000003'
        },
        'D1' => {
          'tube_barcode' => 'AB10000004'
        },
        'E1' => {
          'tube_barcode' => 'AB10000005'
        },
        'F1' => {
          'tube_barcode' => 'AB10000006'
        },
        'G1' => {
          'tube_barcode' => 'AB10000007'
        },
        'H1' => {
          'tube_barcode' => 'AB10000008'
        },
        'A2' => {
          'tube_barcode' => 'AB10000009'
        },
        'B2' => {
          'tube_barcode' => 'AB10000010'
        },
        'C2' => {
          'tube_barcode' => 'AB10000011'
        },
        'D2' => {
          'tube_barcode' => 'AB10000012'
        },
        'E2' => {
          'tube_barcode' => 'AB10000013'
        },
        'F2' => {
          'tube_barcode' => 'AB10000014'
        },
        'G2' => {
          'tube_barcode' => 'AB10000015'
        },
        'H2' => {
          'tube_barcode' => 'AB10000016'
        }
      }
    end

    context 'Without byte order markers' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/common_file_handling/tube_rack/tube_rack_scan_valid.csv',
          'sequencescape/qc_file'
        )
      end

      describe '#valid?' do
        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe '#position_details' do
        it 'parses the expected well details' do
          expect(subject.position_details).to eq expected_position_details
        end
      end
    end

    context 'With byte order markers' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/common_file_handling/tube_rack/tube_rack_scan_with_bom.csv',
          'sequencescape/qc_file'
        )
      end

      describe '#valid?' do
        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe '#position_details' do
        it 'parses the expected well details' do
          expect(subject.position_details).to eq expected_position_details
        end
      end
    end

    context 'A file which has missing tubes' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/common_file_handling/tube_rack/tube_rack_scan_with_missing_tubes.csv',
          'sequencescape/qc_file'
        )
      end

      # missing tube rows should be filtered out e.g. C1 is a NO READ here
      let(:expected_position_details) do
        {
          'A1' => {
            'tube_barcode' => 'AB10000001'
          },
          'B1' => {
            'tube_barcode' => 'AB10000002'
          },
          'D1' => {
            'tube_barcode' => 'AB10000004'
          },
          'E1' => {
            'tube_barcode' => 'AB10000005'
          },
          'F1' => {
            'tube_barcode' => 'AB10000006'
          },
          'G1' => {
            'tube_barcode' => 'AB10000007'
          },
          'H1' => {
            'tube_barcode' => 'AB10000008'
          },
          'B2' => {
            'tube_barcode' => 'AB10000010'
          },
          'C2' => {
            'tube_barcode' => 'AB10000011'
          },
          'D2' => {
            'tube_barcode' => 'AB10000012'
          },
          'E2' => {
            'tube_barcode' => 'AB10000013'
          },
          'F2' => {
            'tube_barcode' => 'AB10000014'
          },
          'H2' => {
            'tube_barcode' => 'AB10000016'
          }
        }
      end

      describe '#valid?' do
        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe '#position_details' do
        it 'parses the expected well details' do
          expect(subject.position_details).to eq expected_position_details
        end
      end
    end
  end

  context 'something that can not parse' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/common_file_handling/tube_rack/tube_rack_scan_valid.csv',
        'sequencescape/qc_file'
      )
    end

    before { allow(CSV).to receive(:parse).and_raise('Really bad file') }

    describe '#valid?' do
      it 'is invalid' do
        expect(subject.valid?).to be false
      end

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include('Could not read csv: Really bad file')
      end
    end
  end

  context 'A file which has missing values' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/common_file_handling/tube_rack/tube_rack_scan_with_missing_values.csv',
        'sequencescape/qc_file'
      )
    end

    describe '#valid?' do
      it 'is invalid' do
        expect(subject.valid?).to be false
      end

      let(:row3_error) { 'Tube rack scan tube barcode cannot be empty, in row 3 [C1]' }

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include(row3_error)
      end
    end
  end

  context 'An invalid file' do
    let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

    describe '#valid?' do
      it 'is invalid' do
        expect(subject.valid?).to be false
      end

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include(
          'Tube rack scan contains an unexpected number of columns (1 expecting 2) at row 1 [This is an example file]'
        )
        expect(subject.errors.full_messages).to include(
          'Tube rack scan tube position contains an invalid coordinate, in row 1 [This is an example file]'
        )
        expect(subject.errors.full_messages).to include(
          'Tube rack scan tube barcode cannot be empty, in row 1 [This is an example file]'
        )
        expect(subject.errors.full_messages).to include(
          'Tube rack scan contains an unexpected number of columns (1 expecting 2) ' \
          'at row 2 [It is used to test qc file upload]'
        )
        expect(subject.errors.full_messages).to include(
          'Tube rack scan tube position contains an invalid coordinate, in row 2 [It is used to test qc file upload]'
        )
        expect(subject.errors.full_messages).to include(
          'Tube rack scan tube barcode cannot be empty, in row 2 [It is used to test qc file upload]'
        )
      end
    end
  end

  context 'An unrecognised tube position' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/common_file_handling/tube_rack/tube_rack_scan_with_invalid_positions.csv',
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
          'Tube rack scan tube position contains an invalid coordinate, in row 9 [I1]'
        )
      end
    end
  end

  # the same position should not appear more than once in the file
  context 'A file with duplicated positions' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/common_file_handling/' \
        'tube_rack/tube_rack_scan_with_duplicate_positions.csv',
        'sequencescape/qc_file'
      )
    end

    describe '#valid?' do
      it 'is invalid' do
        expect(subject.valid?).to be false
      end

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include('contains duplicate rack positions (A2,E2)')
      end
    end
  end

  # the same tube barcode should not appear more than once in the file
  context 'A file with duplicated tube barcodes' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/common_file_handling/tube_rack/tube_rack_scan_with_duplicate_tubes.csv',
        'sequencescape/qc_file'
      )
    end

    describe '#valid?' do
      it 'is not valid' do
        expect(subject.valid?).to be false
      end

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include('contains duplicate tube barcodes (AB10000009,AB10000011)')
      end
    end
  end
end
