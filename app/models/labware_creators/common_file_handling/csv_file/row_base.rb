# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  module CommonFileHandling
    #
    # This is an abstract class for handling rows within csv files.
    # It provides a simple wrapper for handling and validating an individual row.
    #
    class CsvFile::RowBase
      include ActiveModel::Validations

      UNEXPECTED_NUMBER_OF_COLUMNS = 'contains an unexpected number of columns (%s expecting %s) at %s'

      validate :check_has_expected_number_of_columns
      validate :check_for_invalid_characters

      def initialize(index, row_data)
        @index = index
        @row_data = row_data

        initialize_context_specific_fields
      end

      # Override in subclass
      # Example:
      # @my_field_1 = (@row_data[0] || '').strip.upcase
      # @my_field_2 = (@row_data[1] || '').strip.upcase
      def initialize_context_specific_fields
        raise 'Method should be implemented within subclasses'
      end

      # Override in subclass
      # For use in error messages
      # e.g. "row #{index + 2} [#{@my_field_1}]"
      def to_s
        raise 'Method should be implemented within subclasses'
      end

      # Check for whether the row is empty
      # Here all? returns true for an empty array, and nil? returns true for nil elements.
      # So if @row_data is either empty or all nil, empty? will return true.
      def empty?
        @row_data.all?(&:nil?)
      end

      # Override in subclass
      # Returns expected number of columns for this file tyoe
      # e.g. 3
      def expected_number_of_columns
        raise 'Method should be implemented within subclasses'
      end

      # Validation to check if the number of columns in the row matches the expected number.
      # Skip if row is empty, or if we don't want to do the check for this subclass
      def check_has_expected_number_of_columns
        return if empty?

        # ignore check if expected_number_of_columns is set to -1 by subclass
        return if expected_number_of_columns == -1

        return if @row_data.size == expected_number_of_columns

        errors.add(:base, format(UNEXPECTED_NUMBER_OF_COLUMNS, @row_data.size, expected_number_of_columns, to_s))
      end

      # Checking for use of only basic UTF-8 characters (within Rails valid UTF-8 encoding)
      # See https://secure.wikimedia.org/wikipedia/en/wiki/Utf8
      # This check was added to prevent the error 'malformed UTF-8' when writing metadata to the database in
      # labware creator classes
      # e.g. we saw an unusual hyphen which looked like "Twist exome \xE2\x80\x93 humgen" instead of
      # "Twist exome - humgen"
      # This was valid UTF-8 according to rails, but not valid UTF-8 according to the mysql2 gem that was
      # writing to the database (which has a more restricted understanding of what is valid)
      def check_for_invalid_characters
        return if empty?

        @row_data.each_with_index do |cell, i|
          next if cell.nil?
          next if cell_is_valid_utf8?(cell)

          add_invalid_character_error(i)
        end
      end

      private

      def cell_is_valid_utf8?(cell)
        cell.bytes.all? { |byte| byte < 128 } && cell.dup.force_encoding('UTF-8').valid_encoding?
      end

      def add_invalid_character_error(column)
        errors.add(
          :base,
          "contains invalid character(s) at column #{column + 1} in #{self}, " \
          'please use only standard characters and UTF-8 encoding for your csv file'
        )
      end
    end
  end
end
