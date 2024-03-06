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
    class CsvFile::RowForTubeRack < CsvFile::Row
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
        @tube_position = (@row_data[0] || '').strip.upcase
        @tube_barcode = (@row_data[1] || '').strip.upcase
      end

      def to_s
        # NB. index is zero based and no header row here
        @tube_position.present? ? "row #{index + 1} [#{@tube_position}]" : "row #{index + 1}"
      end
    end
  end
end
