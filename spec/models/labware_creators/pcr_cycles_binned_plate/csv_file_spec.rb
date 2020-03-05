# frozen_string_literal: true

RSpec.describe LabwareCreators::PcrCyclesBinnedPlate::CsvFile, with: :uploader do
  context 'A valid file' do
    let(:file) { fixture_file_upload('spec/fixtures/files/duplex_seq_dil_file.csv', 'sequencescape/qc_file') }
    let(:purpose_config) { create :duplex_seq_customer_csv_file_upload_purpose_config }
    let(:csv_file_config) { purpose_config.fetch(:csv_file_upload) }

    describe '#valid?' do
      subject { described_class.new(file, csv_file_config) }

      it { is_expected.to be_valid }
    end

    describe '#well_details' do
      subject { described_class.new(file, csv_file_config) }

      let(:expected_well_details) do
        {
          'A1' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0, 'pcr_cycles' => 14, 'submit_for_sequencing' => 'Y', 'sub_pool' => 1, 'coverage' => 15 },
          'A2' => { 'sample_volume' => 3.2, 'diluent_volume' => 26.8, 'pcr_cycles' => 12, 'submit_for_sequencing' => 'Y', 'sub_pool' => 1, 'coverage' => 15 },
          'B1' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0, 'pcr_cycles' => 14, 'submit_for_sequencing' => 'Y', 'sub_pool' => 1, 'coverage' => 15 },
          'B2' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0, 'pcr_cycles' => 12, 'submit_for_sequencing' => 'Y', 'sub_pool' => 2, 'coverage' => 15 },
          'C2' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0, 'pcr_cycles' => 12, 'submit_for_sequencing' => 'Y', 'sub_pool' => 2, 'coverage' => 15 },
          'D1' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0, 'pcr_cycles' => 12, 'submit_for_sequencing' => 'Y', 'sub_pool' => 2, 'coverage' => 15 },
          'D2' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0, 'pcr_cycles' => 12, 'submit_for_sequencing' => 'Y', 'sub_pool' => 1, 'coverage' => 15 },
          'E1' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0, 'pcr_cycles' => 12, 'submit_for_sequencing' => 'Y', 'sub_pool' => 1, 'coverage' => 30 },
          'E2' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0, 'pcr_cycles' => 14, 'submit_for_sequencing' => 'Y', 'sub_pool' => 1, 'coverage' => 15 },
          'F1' => { 'sample_volume' => 4.0, 'diluent_volume' => 26.0, 'pcr_cycles' => 12, 'submit_for_sequencing' => 'Y', 'sub_pool' => 1, 'coverage' => 15 },
          'F2' => { 'sample_volume' => 30.0, 'diluent_volume' => 0.0, 'pcr_cycles' => 16, 'submit_for_sequencing' => 'N', 'sub_pool' => nil, 'coverage' => nil },
          'G2' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0, 'pcr_cycles' => 14, 'submit_for_sequencing' => 'Y', 'sub_pool' => 1, 'coverage' => 30 },
          'H1' => { 'sample_volume' => 5.0, 'diluent_volume' => 25.0, 'pcr_cycles' => 12, 'submit_for_sequencing' => 'Y', 'sub_pool' => 2, 'coverage' => 30 },
          'H2' => { 'sample_volume' => 3.621, 'diluent_volume' => 27.353, 'pcr_cycles' => 16, 'submit_for_sequencing' => 'Y', 'sub_pool' => 1, 'coverage' => 15 }
        }
      end

      it { expect(subject.well_details).to eq expected_well_details }
    end
  end

  # context 'something that can not parse' do
  #   let(:file) { fixture_file_upload('spec/fixtures/files/pooling_file.csv', 'sequencescape/qc_file') }

  #   before do
  #     allow(CSV).to receive(:parse).and_raise('Really bad file')
  #   end

  #   describe '#valid?' do
  #     subject { described_class.new(file).valid? }

  #     it { is_expected.to be false }

  #     it 'reports the errors' do
  #       thing = described_class.new(file)
  #       thing.valid?
  #       expect(thing.errors.full_messages).to include('Could not read csv: Really bad file')
  #     end
  #   end
  # end

  # context 'A valid file with missing volumes' do
  #   let(:file) { fixture_file_upload('spec/fixtures/files/pooling_file_with_zero_and_blank.csv', 'sequencescape/qc_file') }

  #   describe '#valid?' do
  #     subject { described_class.new(file).valid? }
  #     it { is_expected.to be false }

  #     let(:row2_error) do
  #       'Transfers volume is 0 in row 2 [A1] but a destination has been specified. Either supply a positive volume, or remove the destination.'
  #     end

  #     let(:row3_error) do
  #       'Transfers volume is blank in row 3 [B1] but a destination has been specified. Either supply a positive volume, or remove the destination.'
  #     end

  #     it 'reports the errors' do
  #       thing = described_class.new(file)
  #       thing.valid?
  #       expect(thing.errors.full_messages).to include(row2_error)
  #       expect(thing.errors.full_messages).to include(row3_error)
  #     end
  #   end
  # end

  # context 'An invalid file' do
  #   let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

  #   describe '#valid?' do
  #     subject { described_class.new(file).valid? }

  #     it { is_expected.to be false }

  #     it 'reports the errors' do
  #       thing = described_class.new(file)
  #       thing.valid?
  #       expect(thing.errors.full_messages).to include('Header row source column could not be found in: \'This is an example file\'')
  #     end
  #   end
  # end

  # context 'An unrecognised well' do
  #   let(:file) { fixture_file_upload('spec/fixtures/files/pooling_file_with_invalid_wells.csv', 'sequencescape/qc_file') }

  #   describe '#valid?' do
  #     subject { described_class.new(file).valid? }

  #     it { is_expected.to be false }

  #     it 'reports the errors' do
  #       thing = described_class.new(file)
  #       thing.valid?
  #       expect(thing.errors.full_messages).to include('Transfers source contains an invalid well name: \'I1\'')
  #     end
  #   end
  # end
end
