# frozen_string_literal: true

module LabwareCreators
  require_dependency 'labware_creators/custom_pooled_tubes/csv_file'
  #
  # Class HeaderRow provides a simple wrapper for handling and validating
  # individual CSV rows
  #
  class CustomPooledTubes::CsvFile::Header
    include ActiveModel::Validations

    # Return the index of the respective column.
    attr_reader :source_column, :destination_column, :volume_column

    SOURCE_COLUMN = 'Source Well'
    DEST_COLUMN = 'Dest. well'
    VOL_COLUMN = 'Volume to add to pool'

    validates :source_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }
    validates :destination_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }
    validates :volume_column, presence: { message: ->(object, _data) { "could not be found in: '#{object}'" } }
    #
    # Generates a header from the header row array
    #
    # @param [Array] row The array of fields extracted from the CSV file
    #
    def initialize(row)
      @row = row || []
      @source_column = index_of_header(SOURCE_COLUMN)
      @destination_column = index_of_header(DEST_COLUMN)
      @volume_column = index_of_header(VOL_COLUMN)
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
