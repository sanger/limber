# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/common_file_handling/csv_file_for_tube_rack_with_rack_barcode'

  module CommonFileHandling
    #
    # This is a shared class for handling rows within tube rack csv files.
    # It provides a simple wrapper for handling and validating an individual row
    # A row in this file should contain a tube rack barcode, the tube location (coordinate
    # within the rack) and the tube barcode
    # i.e. Tube Rack Barcode, Tube Position, Tube Barcode
    #
    class CsvFile::RowForTubeRackWithRackBarcode < CsvFile::RowForTubeRack
      attr_reader :tube_rack_barcode

      TUBE_RACK_BARCODE_MISSING = 'cannot be empty, in %s'

      validates :tube_rack_barcode, presence: { message: ->(object, _data) { TUBE_RACK_BARCODE_MISSING % object } }

      def initialize_context_specific_fields
        # NB. cannot use upcase here as unusual characters will cause an exception and this happens before the
        # check_for_invalid_characters validation
        @tube_rack_barcode = (@row_data[0] || '').strip
        @tube_position = (@row_data[1] || '').strip
        @tube_barcode = (@row_data[2] || '').strip
      end

      def expected_number_of_columns
        3
      end
    end
  end
end
