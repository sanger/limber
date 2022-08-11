# frozen_string_literal: true

RSpec.describe LabwareCreators::PcrCyclesBinnedPlate::CsvFile, with: :uploader do
  let(:purpose_config) { create :pcr_cycles_binned_plate_purpose_config }
  let(:csv_file_config) { purpose_config.fetch(:csv_file_upload) }
  let(:bait_library) { create :bait_library, name: 'HybPanel1' }

  subject { described_class.new(file, csv_file_config, 'DN2T') }

  before do
    stub_v2_bait_library(bait_library.name, bait_library)

    # case insensitive versions
    stub_v2_bait_library('hybpanel1', bait_library)
    stub_v2_bait_library('HYBPANEL1', bait_library)
  end

  context 'Valid files' do
    let(:expected_request_metadata_details) do
      {
        'A1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15,
          'bait_library' => 'HybPanel1'
        },
        'B1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15,
          'bait_library' => 'HybPanel1'
        },
        'D1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 16,
          'submit_for_sequencing' => true,
          'sub_pool' => 2,
          'coverage' => 15,
          'bait_library' => 'HybPanel1'
        },
        'E1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 30,
          'bait_library' => 'HybPanel1'
        },
        'F1' => {
          'sample_volume' => 4.0,
          'diluent_volume' => 26.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15,
          'bait_library' => 'HybPanel1'
        },
        'H1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 2,
          'coverage' => 30,
          'bait_library' => 'HybPanel1'
        },
        'A2' => {
          'sample_volume' => 3.2,
          'diluent_volume' => 26.8,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15,
          'bait_library' => 'HybPanel1'
        },
        'B2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 2,
          'coverage' => 15,
          'bait_library' => 'HybPanel1'
        },
        'C2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 2,
          'coverage' => 15,
          'bait_library' => 'HybPanel1'
        },
        'D2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15,
          'bait_library' => 'HybPanel1'
        },
        'E2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15,
          'bait_library' => 'HybPanel1'
        },
        'F2' => {
          'sample_volume' => 30.0,
          'diluent_volume' => 0.0,
          'pcr_cycles' => 16,
          'submit_for_sequencing' => false,
          'sub_pool' => nil,
          'coverage' => nil,
          'bait_library' => 'HybPanel1'
        },
        'G2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 30,
          'bait_library' => 'HybPanel1'
        },
        'H2' => {
          'sample_volume' => 3.621,
          'diluent_volume' => 27.353,
          'pcr_cycles' => 16,
          'submit_for_sequencing' => true,
          'sub_pool' => 1,
          'coverage' => 15,
          'bait_library' => 'HybPanel1'
        }
      }
    end

    context 'Without byte order markers' do
      let(:file) do
        fixture_file_upload('spec/fixtures/files/pcr_cycles_binned_plate_dil_file.csv', 'sequencescape/qc_file')
      end

      describe '#valid?' do
        it 'should be valid' do
          expect(subject.valid?).to be true
        end
      end

      describe '#request_metadata_details' do
        it 'should parse the expected request metadata details' do
          expect(subject.request_metadata_details).to eq expected_request_metadata_details
        end
      end
    end

    context 'With byte order markers' do
      let(:file) do
        fixture_file_upload(
          'spec/fixtures/files/pcr_cycles_binned_plate_dil_file_with_bom.csv',
          'sequencescape/qc_file'
        )
      end

      describe '#valid?' do
        it 'should be valid' do
          expect(subject.valid?).to be true
        end
      end

      describe '#request_metadata_details' do
        it 'should parse the expected request metadata details' do
          expect(subject.request_metadata_details).to eq expected_request_metadata_details
        end
      end
    end
  end

  context 'When there is something in the file that we cannot parse' do
    let(:file) do
      fixture_file_upload('spec/fixtures/files/pcr_cycles_binned_plate_dil_file.csv', 'sequencescape/qc_file')
    end

    before { allow(CSV).to receive(:parse).and_raise('Really bad file') }

    describe '#valid?' do
      it 'should be invalid' do
        expect(subject.valid?).to be false
      end

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include('Could not read csv: Really bad file')
      end
    end
  end

  context 'When the file has missing well values' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/pcr_cycles_binned_plate_dil_file_with_missing_values.csv',
        'sequencescape/qc_file'
      )
    end

    describe '#valid?' do
      it 'should be invalid' do
        expect(subject.valid?).to be false
      end

      let(:row4_error) do
        'Transfers input amount desired is empty or contains a value that is out of range (0.0 to 50.0), in row 4 [A1]'
      end

      let(:row5_error) do
        'Transfers sample volume is empty when it should have a value of zero, or between the two values ' \
          'specified in configuration, in row 5 [B1]'
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

  context 'When the file is invalid' do
    let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

    describe '#valid?' do
      it 'should be invalid' do
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

  context 'When there is an unrecognised well coordinate' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/pcr_cycles_binned_plate_dil_file_with_invalid_wells.csv',
        'sequencescape/qc_file'
      )
    end

    describe '#valid?' do
      it 'should be invalid' do
        expect(subject.valid?).to be false
      end

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include('Transfers well contains an invalid well name, in row 11 [I1]')
      end
    end
  end

  context 'When a parent plate barcode does not match the file header row' do
    subject { described_class.new(file, csv_file_config, 'DN1S') }

    let(:file) do
      fixture_file_upload('spec/fixtures/files/pcr_cycles_binned_plate_dil_file.csv', 'sequencescape/qc_file')
    end

    describe '#valid?' do
      it 'should be invalid' do
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

  context 'When there is an invalid Hyb Panel value' do
    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/pcr_cycles_binned_plate_dil_file_with_invalid_hyb_panel.csv',
        'sequencescape/qc_file'
      )
    end

    before { stub_v2_bait_library('HybPanelUnknown', nil) }

    describe '#valid?' do
      it 'should be invalid' do
        expect(subject.valid?).to be false
      end

      it 'reports the errors' do
        subject.valid?
        expect(subject.errors.full_messages).to include(
          'Transfers hyb panel contains an invalid hyb panel (bait library) name, in row 7 [D1]'
        )
      end
    end
  end

  context 'When some sample volumes are set to zero to indicate the samples should not proceed' do
    subject { described_class.new(file, csv_file_config, 'DN2T') }

    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/pcr_cycles_binned_plate_dil_file_with_zero_sample_volumes.csv',
        'sequencescape/qc_file'
      )
    end

    describe '#valid?' do
      it 'should be valid' do
        expect(subject.valid?).to be true
      end

      it 'should have the expected wells included in the request metadata details', aggregate_failures: true do
        expect(subject.request_metadata_details.size).to eq(10)
        expect(subject.request_metadata_details.keys).to match(%w[A1 B1 D1 F1 H1 A2 C2 D2 G2 H2])
        expect(subject.skipped_wells).to match(%w[E1 B2 E2 F2])
      end
    end
  end

  context 'When all sample volumes are set to zero' do
    subject { described_class.new(file, csv_file_config, 'DN2T') }

    let(:file) do
      fixture_file_upload(
        'spec/fixtures/files/pcr_cycles_binned_plate_dil_file_with_all_zero_sample_volumes.csv',
        'sequencescape/qc_file'
      )
    end

    describe '#valid?' do
      # NB. this scenario is caught as an error at the next level up, in the creator
      it 'should be valid' do
        expect(subject.valid?).to be true
      end

      it 'should have empty request metadata details and all zero rows skipped', aggregate_failures: true do
        expect(subject.request_metadata_details.size).to eq(0)
        expect(subject.skipped_wells).to match(%w[A1 B1 D1 E1 F1 H1 A2 B2 C2 D2 E2 F2 G2 H2])
      end
    end
  end
end
