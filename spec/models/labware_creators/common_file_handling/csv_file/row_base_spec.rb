# frozen_string_literal: true

require_dependency 'well_helpers'

RSpec.describe LabwareCreators::CommonFileHandling::CsvFile::RowBase do
  # This is an abstract class, and we need to override the initialize_context_specific_fields method
  subject { described_class.new(1, row_data) }

  before do
    allow_any_instance_of(described_class).to receive(:initialize_context_specific_fields)
    subject.instance_variable_set(:@row_data, row_data)
    allow(subject).to receive(:expected_number_of_columns).and_return(2)
    allow(subject).to receive(:to_s).and_return('row 1 [A1]')
  end

  let(:row_position) { 'A1' }
  let(:row_barcode) { 'AB10000001' }
  let(:row_data) { [row_position, row_barcode] }

  # Testing the validation for invalid characters
  describe '#check_for_invalid_characters' do
    context 'when row_data is empty' do
      let(:row_data) { [] }

      it 'does not add any errors' do
        subject.check_for_invalid_characters
        expect(subject.errors.full_messages).to be_empty
      end
    end

    context 'when row_data contains only valid characters' do
      it 'does not add any errors' do
        subject.check_for_invalid_characters
        expect(subject.errors.full_messages).to be_empty
      end
    end

    context 'when row_data contains invalid characters' do
      let(:row_barcode) { "inval\x80id" }

      it 'adds an error for the invalid character' do
        subject.check_for_invalid_characters
        expect(subject.errors.full_messages).to include(
          "contains invalid character(s) at column 2 in #{subject}, " \
          'please use only standard characters and UTF-8 encoding for your csv file'
        )
      end
    end

    context 'when row_data contains valid characters with invisible spaces' do
      let(:row_barcode) { "some\u00A0 data" } # \u00A0 is a non-breaking space

      it 'adds an error for the invisible space' do
        subject.check_for_invalid_characters
        expect(subject.errors.full_messages).to include(
          "contains invalid character(s) at column 2 in #{subject}, " \
          'please use only standard characters and UTF-8 encoding for your csv file'
        )
      end
    end

    context 'when row_data contains only spaces' do
      let(:row_barcode) { '    ' }

      it 'does not add any errors' do
        subject.check_for_invalid_characters
        expect(subject.errors.full_messages).to be_empty
      end
    end

    context 'when row_data contains spaces with invisible characters' do
      let(:row_barcode) { " \u200B \u200B " } # \u200B is a zero-width space

      it 'adds an error for the invisible space' do
        subject.check_for_invalid_characters
        expect(subject.errors.full_messages).to include(
          "contains invalid character(s) at column 2 in #{subject}, " \
          'please use only standard characters and UTF-8 encoding for your csv file'
        )
      end
    end

    context 'when row_data contains invalid invisible characters' do
      let(:row_barcode) { "\u200Csome data\u200C" } # \u200C is a zero-width non-joiner

      it 'adds an error for the invalid invisible character' do
        subject.check_for_invalid_characters
        expect(subject.errors.full_messages).to include(
          "contains invalid character(s) at column 2 in #{subject}, " \
          'please use only standard characters and UTF-8 encoding for your csv file'
        )
      end
    end

    context 'when row_data contains valid characters and nil cells' do
      let(:row_data) { ['A1', '', nil] }

      it 'does not add any errors' do
        subject.check_for_invalid_characters
        expect(subject.errors.full_messages).to be_empty
      end
    end
  end

  # Testing the validation for the number of columns
  describe '#check_has_expected_number_of_columns' do
    # let(:errors) { double('Errors', add: nil) }

    before do
      # allow(subject).to receive(:errors).and_return(errors)
      allow(subject).to receive(:expected_number_of_columns).and_return(expected_number_of_columns)
    end

    context 'when row_data is empty' do
      let(:row_data) { [] }
      let(:expected_number_of_columns) { 2 }

      it 'does not add any errors' do
        subject.check_has_expected_number_of_columns
        expect(subject.errors.full_messages).to be_empty
      end
    end

    context 'when expected_number_of_columns is -1' do
      let(:row_data) { ['data'] }
      let(:expected_number_of_columns) { -1 }

      it 'does not add any errors' do
        subject.check_has_expected_number_of_columns
        expect(subject.errors.full_messages).to be_empty
      end
    end

    context 'when row_data has the expected number of columns' do
      let(:row_data) { %w[data1 data2] }
      let(:expected_number_of_columns) { 2 }

      it 'does not add any errors' do
        subject.check_has_expected_number_of_columns
        expect(subject.errors.full_messages).to be_empty
      end
    end

    context 'when row_data does not have the expected number of columns' do
      let(:row_data) { %w[data1 data2 data3] }
      let(:expected_number_of_columns) { 2 }

      it 'adds an error' do
        subject.check_has_expected_number_of_columns
        expect(subject.errors.full_messages).to include(
          "contains an unexpected number of columns (#{row_data.size} expecting " \
          "#{expected_number_of_columns}) at #{subject}"
        )
      end
    end
  end
end
