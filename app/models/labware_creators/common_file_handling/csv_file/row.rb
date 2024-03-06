# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  module CommonFileHandling
    #
    # This is an abstract class for handling rows within csv files.
    # It provides a simple wrapper for handling and validating an individual row.
    #
    class CsvFile::Row
      include ActiveModel::Validations

      def initialize(index, row_data)
        @index = index
        @row_data = row_data

        # initialize context specific fields
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
      def empty?
        @row_data.empty? || @row_data.compact.empty?
      end
    end
  end
end
