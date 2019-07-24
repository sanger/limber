# frozen_string_literal: true

RSpec.describe LabwareCreators::CustomPooledTubes::CsvFile, with: :uploader do
  context 'A valid file' do
    let(:file) { fixture_file_upload('spec/fixtures/files/pooling_file.csv', 'sequencescape/qc_file') }

    describe '#valid?' do
      subject { described_class.new(file) }

      it { is_expected.to be_valid }
    end

    describe '#pools' do
      subject { described_class.new(file).pools }
      let(:expected_pools) do
        {
          '1' => %w[A1 B1 D1 E1 F1 G1 H1 A2 B2],
          '2' => %w[C1 C2 D2 E2 F2 G2]
        }
      end
      it { is_expected.to eq expected_pools }
    end
  end

  context 'something that can not parse' do
    let(:file) { fixture_file_upload('spec/fixtures/files/pooling_file.csv', 'sequencescape/qc_file') }

    before do
      allow(CSV).to receive(:parse).and_raise('Really bad file')
    end

    describe '#valid?' do
      subject { described_class.new(file).valid? }

      it { is_expected.to be false }

      it 'reports the errors' do
        thing = described_class.new(file)
        thing.valid?
        expect(thing.errors.full_messages).to include('Could not read csv: Really bad file')
      end
    end
  end

  context 'A valid file with missing volumes' do
    let(:file) { fixture_file_upload('spec/fixtures/files/pooling_file_with_zero_and_blank.csv', 'sequencescape/qc_file') }

    describe '#valid?' do
      subject { described_class.new(file).valid? }
      it { is_expected.to be false }

      let(:row2_error) do
        'Transfers volume is 0 in row 2 [A1] but a destination has been specified. Either supply a positive volume, or remove the destination.'
      end

      let(:row3_error) do
        'Transfers volume is blank in row 3 [B1] but a destination has been specified. Either supply a positive volume, or remove the destination.'
      end

      it 'reports the errors' do
        thing = described_class.new(file)
        thing.valid?
        expect(thing.errors.full_messages).to include(row2_error)
        expect(thing.errors.full_messages).to include(row3_error)
      end
    end
  end

  context 'An invalid file' do
    let(:file) { fixture_file_upload('spec/fixtures/files/test_file.txt', 'sequencescape/qc_file') }

    describe '#valid?' do
      subject { described_class.new(file).valid? }

      it { is_expected.to be false }

      it 'reports the errors' do
        thing = described_class.new(file)
        thing.valid?
        expect(thing.errors.full_messages).to include('Header row source column could not be found in: \'This is an example file\'')
      end
    end
  end

  context 'An unrecognised well' do
    let(:file) { fixture_file_upload('spec/fixtures/files/pooling_file_with_invalid_wells.csv', 'sequencescape/qc_file') }

    describe '#valid?' do
      subject { described_class.new(file).valid? }

      it { is_expected.to be false }

      it 'reports the errors' do
        thing = described_class.new(file)
        thing.valid?
        expect(thing.errors.full_messages).to include('Transfers source contains an invalid well name: \'I1\'')
      end
    end
  end
end
