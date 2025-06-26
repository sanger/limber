# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pcr_cycles_binned_plate/csv_file_base'

  #
  # Class PlateBarcodeHeader provides a simple wrapper for handling and validating
  # the plate barcode header row from the customer csv file
  #
  # Row looks like this:
  #
  # Plate Barcode,DN9000041H
  #
  class PcrCyclesBinnedPlate::CsvFile::PlateBarcodeHeader
    include ActiveModel::Validations

    # Return the index of the respective column.
    attr_reader :barcode_lbl_index

    BARCODE_LABEL_TEXT = 'Plate Barcode'
    BARCODE_NOT_MATCHING =
      'The plate barcode in the file (%s) does not match the barcode of ' \
      'the plate being uploaded to (%s), please check you have the correct file.'
    NOT_FOUND = 'could not be found in: '

    validates :barcode_lbl_index, presence: { message: ->(object, _data) { "#{NOT_FOUND}'#{object}'" } }
    validates :plate_barcode, presence: { message: ->(object, _data) { "#{NOT_FOUND}'#{object}'" } }
    validate :plate_barcode_matches_parent?

    #
    # Generates a plate barcode header from the plate barcode header row array
    #
    # @param [Array] row The array of fields extracted from the CSV file
    #
    def initialize(parent_barcode, row)
      @parent_barcode = parent_barcode
      @row = row || []

      @barcode_lbl_index = index_of_header(BARCODE_LABEL_TEXT)
    end

    def plate_barcode
      @plate_barcode =
        (@row[@barcode_lbl_index + 1].strip if @barcode_lbl_index.present? && @row[@barcode_lbl_index + 1].present?)
    end

    #
    # Outputs the header as a string
    #
    # @return [<String] Outputs the raw header data
    #
    def to_s
      @row.join(',')
    end

    def plate_barcode_matches_parent?
      return true if @parent_barcode == plate_barcode

      errors.add('plate_barcode', format(BARCODE_NOT_MATCHING, plate_barcode, @parent_barcode))
    end

    private

    #
    # Returns the index of the given column name. Returns nil if the column can't be found.
    # Uses strip and case insensitive matching
    #
    # @param [String] column_header The header of the column to find
    #
    # @return [Int,nil] The index of the header in the column list. nil is missing.
    #
    def index_of_header(column_header)
      @row.index { |value| value.respond_to?(:strip) && column_header.casecmp?(value.strip) }
    end
  end
end
