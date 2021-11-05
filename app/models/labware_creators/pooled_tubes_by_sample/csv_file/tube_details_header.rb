# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/pooled_tubes_by_sample/csv_file'
  #
  # Class TubeDetailsHeader provides a simple wrapper for handling and validating
  # the header row from the tube rack scan csv file
  #
  class PooledTubesBySample::CsvFile::TubeDetailsHeader
    include ActiveModel::Validations

    # Return the index of the respective column.
    attr_reader :position_column, :barcode_column

    POSITION_COLUMN = 'Position'
    BARCODE_COLUMN = 'Barcode'

    validates :position_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }
    validates :barcode_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }

    #
    # Generates a tube location details header from the tube location details header row array
    #
    # @param [Array] row The array of fields extracted from the CSV file
    #
    def initialize(row)
      @row = row || []

      @position_column = index_of_header(POSITION_COLUMN)
      @barcode_column = index_of_header(BARCODE_COLUMN)
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
