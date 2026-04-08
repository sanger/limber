# frozen_string_literal: true

RSpec.describe LabwareCreators::PcrCyclesBinnedPlate::CsvFileForTNanoSeq, with: :uploader do
  subject { described_class.new(file, csv_file_config, 'DN2T') }

  let(:purpose_config) { create :targeted_nano_seq_customer_csv_file_upload_purpose_config }
  let(:csv_file_config) { purpose_config.fetch(:csv_file_upload) }

  context 'Valid files' do
    let(:expected_well_details) do
      {
        'A1' => {
          'concentration' => 0.686,
          'input_amount_available' => 17.150000000000002,
          'input_amount_desired' => 0.0,
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'hyb_panel' => 'My Panel'
        },
        'B1' => {
          'concentration' => 0.623,
          'input_amount_available' => 15.575,
          'input_amount_desired' => 50.0,
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'hyb_panel' => 'My Panel'
        },
        'D1' => {
          'concentration' => 1.874,
          'input_amount_available' => 46.85,
          'input_amount_desired' => 49.9,
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 16,
          'hyb_panel' => 'My Panel'
        },
        'E1' => {
          'concentration' => 1.929,
          'input_amount_available' => 48.225,
          'input_amount_desired' => 0.1,
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'hyb_panel' => 'My Panel'
        },
        'F1' => {
          'concentration' => 1.700,
          'input_amount_available' => 42.5,
          'input_amount_desired' => 50.0,
          'sample_volume' => 4.0,
          'diluent_volume' => 26.0,
          'pcr_cycles' => 12,
          'hyb_panel' => 'My Panel'
        },
        'H1' => {
          'concentration' => 1.838,
          'input_amount_available' => 45.95,
          'input_amount_desired' => 37.3,
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'hyb_panel' => 'My Panel'
        },
        'A2' => {
          'concentration' => 1.581,
          'input_amount_available' => 39.525,
          'input_amount_desired' => 50.0,
          'sample_volume' => 3.2,
          'diluent_volume' => 26.8,
          'pcr_cycles' => 12,
          'hyb_panel' => 'My Panel'
        },
        'B2' => {
          'concentration' => 1.538,
          'input_amount_available' => 38.45,
          'input_amount_desired' => 34.8,
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'hyb_panel' => 'My Panel'
        },
        'C2' => {
          'concentration' => 1.560,
          'input_amount_available' => 39.0,
          'input_amount_desired' => 50.0,
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'hyb_panel' => 'My Panel'
        },
        'D2' => {
          'concentration' => 1.479,
          'input_amount_available' => 36.975,
          'input_amount_desired' => 50.0,
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'hyb_panel' => 'My Panel'
        },
        'E2' => {
          'concentration' => 0.734,
          'input_amount_available' => 18.35,
          'input_amount_desired' => 50.0,
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'hyb_panel' => 'My Panel'
        },
        'F2' => {
          'concentration' => 0.000,
          'input_amount_available' => 0.0,
          'input_amount_desired' => 39.2,
          'sample_volume' => 30.0,
          'diluent_volume' => 0.0,
          'pcr_cycles' => 16,
          'hyb_panel' => 'My Panel'
        },
        'G2' => {
          'concentration' => 0.741,
          'input_amount_available' => 18.525,
          'input_amount_desired' => 50.0,
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'hyb_panel' => 'My Panel'
        },
        'H2' => {
          'concentration' => 0.196,
          'input_amount_available' => 4.9,
          'input_amount_desired' => 50.0,
          'sample_volume' => 3.621,
          'diluent_volume' => 27.353,
          'pcr_cycles' => 16,
          'hyb_panel' => 'My Panel'
        }
      }
    end

    context 'Without byte order markers' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file.csv',
          'sequencescape/qc_file'
        )
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
        fixture_file_upload(
          'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file_with_bom.csv',
          'sequencescape/qc_file'
        )
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
      fixture_file_upload(
        'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file.csv',
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

  context 'A file which has missing well values' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file_with_missing_values.csv',
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

      let(:row11_error) { 'Transfers hyb panel is empty, in row 11 [A2]' }

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include(row4_error)
        expect(subject.errors.full_messages).to include(row5_error)
        expect(subject.errors.full_messages).to include(row6_error)
        expect(subject.errors.full_messages).to include(row7_error)
        expect(subject.errors.full_messages).to include(row11_error)
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
        'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file_with_invalid_wells.csv',
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
      fixture_file_upload(
        'spec/fixtures/files/targeted_nano_seq/targeted_nano_seq_dil_file.csv',
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
          'Plate barcode header row plate barcode The plate barcode in the file (DN2T) does not match the ' \
          'barcode of the plate being uploaded to (DN1S), please check you have the correct file.'
        )
      end
    end
  end
end
