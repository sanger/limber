# frozen_string_literal: true

# spec/lib/labware_creators/ultima_balancing_csv_file_spec.rb
require 'rails_helper'
require 'csv'

RSpec.describe LabwareCreators::BalancedPooledTube::UltimaBalancingCsvFile do
  let(:valid_csv_content) do
    <<~CSV
      sample,,,,S1,S2
      barcode,TT,UNKN,RANDOM,Z0001,Z0002
      pf_barcode_reads,2333,1111,2222,79229127,70266606
      mean_cvg,2.34,66.65,12.22,6.69,5.95
    CSV
  end

  let(:tempfile) do
    f = Tempfile.new(['12345_rebalance', '.csv'])
    f.write(valid_csv_content)
    f.rewind
    f
  end

  let(:file) do
    ActionDispatch::Http::UploadedFile.new(
      origin_filename: '12345_rebalance.csv',
      filename: '12345_rebalance.csv',
      type: 'text/csv',
      tempfile: tempfile
    )
  end

  after do
    tempfile.close
    tempfile.unlink
    file.close
    extra_tempfiles.each(&:close!)
  end

  let!(:extra_tempfiles) { [] }

  def build_uploaded_file(content, name: '12345_rebalance.csv')
    tempfile = Tempfile.new([File.basename(name, '.csv'), '.csv'])
    tempfile.write(content)
    tempfile.rewind
    extra_tempfiles << tempfile

    ActionDispatch::Http::UploadedFile.new(
      filename: name,
      type: 'text/csv',
      tempfile: tempfile
    )
  end

  describe '#initialize' do
    it 'parses the CSV and extracts all expected fields' do
      csv_file = described_class.new(file)
      expect(csv_file).to have_attributes(
        samples: %w[S1 S2],
        barcodes: %w[Z0001 Z0002],
        pf_barcode_reads: [79_229_127, 70_266_606],
        mean_cvg: [6.69, 5.95],
        parse_error: nil
      )
    end

    it 'records a parse error if CSV parsing fails' do
      allow(CSV).to receive(:read).and_raise(StandardError, 'CSV broken')
      csv_file = described_class.new(file)
      expect(csv_file.parse_error).to eq('CSV broken')
    end
  end

  describe 'validations' do
    context 'with a valid CSV' do
      it 'is valid' do
        csv_file = described_class.new(file)
        expect(csv_file.valid?).to be true
      end

      it 'extracts the batch_id from the filename' do
        csv_file = described_class.new(file)
        csv_file.validate!
        expect(csv_file.batch_id).to eq(12_345)
      end
    end

    context 'with an invalid filename' do
      it 'fails if the filename does not start with a numeric batch ID' do
        allow(file).to receive(:original_filename).and_return('abc_rebalance.csv')
        csv_file = described_class.new(file)
        csv_file.valid?
        expect(csv_file.errors.full_messages).to include(
          'Filename must start with a numeric batch ID followed by an underscore'
        )
      end
    end

    context 'with an empty samples row' do
      let(:empty_samples_csv) do
        <<~CSV
          sample,
          barcode,Z0001
          pf_barcode_reads,100
          mean_cvg,5.0
        CSV
      end

      it 'fails with a descriptive error message' do
        file = build_uploaded_file(empty_samples_csv)
        csv_file = described_class.new(file)
        csv_file.valid?
        expect(csv_file.errors.full_messages).to include('Samples row must have at least one sample')
      end
    end

    context 'when the number of data values does not match the number of samples' do
      let(:mismatched_csv) do
        <<~CSV
          sample,S1,S2
          barcode,Z0001
          pf_barcode_reads,100,200
          mean_cvg,5.0,6.0
        CSV
      end

      it 'fails with a mismatch error for barcode values' do
        file = build_uploaded_file(mismatched_csv)
        csv_file = described_class.new(file)
        csv_file.valid?
        expect(csv_file.errors.full_messages).to include('Number of barcode values must match number of samples')
      end
    end

    context 'when required data rows are missing or empty' do
      let(:incomplete_csv) do
        <<~CSV
          sample,S1,S2
          barcode,Z0001,Z002
          pf_barcode_reads,100,200,300
          mean_cvg
        CSV
      end

      it 'fails with a missing values error for the mean_cvg row' do
        file = build_uploaded_file(incomplete_csv)
        csv_file = described_class.new(file)
        csv_file.valid?
        expect(csv_file.errors.full_messages).to include('mean_cvg row must have at least one value')
      end
    end
  end

  describe '#calculate_balancing_variables' do
    before do
      calculator_double = instance_double(
        LabwareCreators::BalancedPooledTube::BalancingCalculator,
        calculate: { 0 => {} }
      )
      allow(LabwareCreators::BalancedPooledTube::BalancingCalculator).to receive(:new).and_return(calculator_double)
    end

    it 'delegates to BalancingCalculator with the parsed CSV data' do
      csv_file = described_class.new(file)
      csv_file.validate!
      csv_file.calculate_balancing_variables
      expect(LabwareCreators::BalancedPooledTube::BalancingCalculator).to have_received(:new).with(
        %w[S1 S2],
        %w[Z0001 Z0002],
        csv_file.pf_barcode_reads,
        csv_file.mean_cvg,
        12_345
      )
    end
  end
end
