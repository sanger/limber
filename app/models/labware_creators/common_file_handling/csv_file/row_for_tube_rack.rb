# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/common_file_handling/csv_file_for_tube_rack'

  module CommonFileHandling
    #
    # This is an shared class for handling rows within tube rack csv files.
    # It provides a simple wrapper for handling and validating an individual row
    # A row in this file should contain a tube location (coordinate within rack)
    # and a tube barcode
    # i.e. Tube Position, Tube Barcode
    #
    class CsvFile::RowForTubeRack < CsvFile::RowBase
      TUBE_LOCATION_NOT_RECOGNISED = 'contains an invalid coordinate, in %s'
      TUBE_BARCODE_MISSING = 'cannot be empty, in %s'

      attr_reader :tube_position, :tube_barcode, :index

      validates :tube_position,
                inclusion: {
                  in: WellHelpers.column_order,
                  message: ->(object, _data) { TUBE_LOCATION_NOT_RECOGNISED % object }
                },
                unless: :empty?
      validates :tube_barcode, presence: { message: ->(object, _data) { TUBE_BARCODE_MISSING % object } }

      def initialize_context_specific_fields
        # NB. cannot use upcase here as unusual characters will cause an exception and this happens before the
        # check_for_invalid_characters validation
        @tube_position = (@row_data[0] || '').strip
        @tube_barcode = (@row_data[1] || '').strip
      end

      def to_s
        # NB. index is zero based and no header row here
        row_number = @index + 1
        @tube_position.present? ? "row #{row_number} [#{@tube_position}]" : "row #{row_number}"
      end

      def expected_number_of_columns
        2
      end
    end
  end
end
