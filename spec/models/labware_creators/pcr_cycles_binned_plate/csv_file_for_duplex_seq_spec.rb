# frozen_string_literal: true

RSpec.describe LabwareCreators::PcrCyclesBinnedPlate::CsvFileForDuplexSeq, with: :uploader do
  subject { described_class.new(file, csv_file_config, 'DN2T') }

  let(:purpose_config) { create :duplex_seq_customer_csv_file_upload_purpose_config }
  let(:csv_file_config) { purpose_config.fetch(:csv_file_upload) }

  context 'Valid files' do
    let(:expected_well_details) do
      {
        'A1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15
        },
        'B1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15
        },
        'D1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 16,
          'submit_for_sequencing' => true,
          'sub_pool' => 2,
          'coverage' => 15
        },
        'E1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 30
        },
        'F1' => {
          'sample_volume' => 4.0,
          'diluent_volume' => 26.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15
        },
        'H1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 2,
          'coverage' => 30
        },
        'A2' => {
          'sample_volume' => 3.2,
          'diluent_volume' => 26.8,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15
        },
        'B2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 2,
          'coverage' => 15
        },
        'C2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 2,
          'coverage' => 15
        },
        'D2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15
        },
        'E2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15
        },
        'F2' => {
          'sample_volume' => 30.0,
          'diluent_volume' => 0.0,
          'pcr_cycles' => 16,
          'submit_for_sequencing' => false,
          'sub_pool' => nil,
          'coverage' => nil
        },
        'G2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 30
        },
        'H2' => {
          'sample_volume' => 3.621,
          'diluent_volume' => 27.353,
          'pcr_cycles' => 16,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15
        }
      }
    end

    context 'Without byte order markers' do
      let(:file) do
        fixture_file_upload('spec/fixtures/files/duplex_seq/duplex_seq_dil_file.csv', 'sequencescape/qc_file')
      end

      describe '#valid?' do
        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe '#well_details' do
        it 'parses the expected well details' do
          expect(subject.well_details).to eq expected_well_details
        end
      end
    end

    context 'With byte order markers' do
      let(:file) do
        fixture_file_upload('spec/fixtures/files/duplex_seq/duplex_seq_dil_file_with_bom.csv', 'sequencescape/qc_file')
      end

      describe '#valid?' do
        it 'is valid' do
          expect(subject.valid?).to be true
        end
      end

      describe '#well_details' do
        it 'parses the expected well details' do
          expect(subject.well_details).to eq expected_well_details
        end
      end
    end
  end

  context 'something that can not parse' do
    let(:file) do
      fixture_file_upload('spec/fixtures/files/duplex_seq/duplex_seq_dil_file.csv', 'sequencescape/qc_file')
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

  context 'A file which has missing well values' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/duplex_seq/duplex_seq_dil_file_with_missing_values.csv',
        'sequencescape/qc_file'
      )
    end

    describe '#valid?' do
      it 'is invalid' do
        expect(subject.valid?).to be false
      end

      let(:row4_error) do
        'Transfers input amount desired is empty or contains a value that is out of range (0.0 to 50.0), in row 4 [A1]'
      end

      let(:row5_error) do
        'Transfers sample volume is empty or contains a value that is out of range (0.2 to 50.0), in row 5 [B1]'
      end

      let(:row6_error) do
        'Transfers diluent volume is empty or contains a value that is out of range (0.0 to 50.0), in row 7 [D1]'
      end

      let(:row7_error) do
        'Transfers pcr cycles is empty or contains a value that is out of range (1 to 20), in row 8 [E1]'
      end

      let(:row8_error) do
        'Transfers submit for sequencing is empty or has an unrecognised value (should be Y or N), in row 9 [F1]'
      end

      let(:row8_error2) do
        'Transfers sub pool has a value when Submit for Sequencing is N, it should be empty, in row 9 [F1]'
      end

      let(:row9_error) do
        'Transfers sub pool is empty or contains a value that is out of range (1 to 96), in row 10 [H1]'
      end

      let(:row10_error) do
        'Transfers coverage is missing but should be present when Submit for Sequencing is Y, in row 11 [A2]'
      end

      let(:row10_error2) { 'Transfers coverage is negative but should be a positive value, in row 11 [A2]' }

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include(row4_error)
        expect(subject.errors.full_messages).to include(row5_error)
        expect(subject.errors.full_messages).to include(row6_error)
        expect(subject.errors.full_messages).to include(row7_error)
        expect(subject.errors.full_messages).to include(row8_error)
        expect(subject.errors.full_messages).to include(row8_error2)
        expect(subject.errors.full_messages).to include(row9_error)
        expect(subject.errors.full_messages).to include(row10_error)
        expect(subject.errors.full_messages).to include(row10_error2)
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
          'Plate barcode header row barcode lbl index could not be found in: \'This is an example file\''
        )
        expect(subject.errors.full_messages).to include(
          'Plate barcode header row plate barcode could not be found in: \'This is an example file\''
        )
        expect(subject.errors.full_messages).to include('Well details header row can\'t be blank')
      end
    end
  end

  context 'An unrecognised well' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/duplex_seq/duplex_seq_dil_file_with_invalid_wells.csv',
        'sequencescape/qc_file'
      )
    end

    describe '#valid?' do
      it 'is invalid' do
        expect(subject.valid?).to be false
      end

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include('Transfers well contains an invalid well name: row 11 [I1]')
      end
    end
  end

  context 'A parent plate barcode that does not match' do
    subject { described_class.new(file, csv_file_config, 'DN1S') }

    let(:file) do
      fixture_file_upload('spec/fixtures/files/duplex_seq/duplex_seq_dil_file.csv', 'sequencescape/qc_file')
    end

    describe '#valid?' do
      it 'is invalid' do
        expect(subject.valid?).to be false
      end

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include(
          'Plate barcode header row plate barcode The plate barcode in the file (DN2T) does not match the ' \
          'barcode of the plate being uploaded to (DN1S), please check you have the correct file.'
        )
      end
    end
  end
end
