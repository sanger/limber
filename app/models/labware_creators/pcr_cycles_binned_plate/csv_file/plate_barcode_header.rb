# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/custom_pooled_tubes/csv_file'
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
    attr_reader :plate_barcode_label_index

    PLATE_BARCODE_LABEL_TEXT = 'Plate Barcode'

    validates :plate_barcode_label_index, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }
    validates :plate_barcode, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }

    #
    # Generates a plate barcode header from the plate barcode header row array
    #
    # @param [Array] row The array of fields extracted from the CSV file
    #
    def initialize(row)
      @row = row || []

      @plate_barcode_label_index = index_of_header(PLATE_BARCODE_LABEL_TEXT)
    end

    def plate_barcode
      @plate_barcode = @row[@plate_barcode_label_index + 1] ||= nil
    end

    #
    # Outputs the header as a string
    #
    # @return [<String] Outputs the raw header data
    #
    def to_s
      @row.join(',')
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
      @row.index do |value|
        value.respond_to?(:strip) && column_header.casecmp?(value.strip)
      end
    end
  end
end
