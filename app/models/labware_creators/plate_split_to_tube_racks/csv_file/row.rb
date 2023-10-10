# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/plate_split_to_tube_racks/csv_file'

  #
  # Provides a simple wrapper for handling and validating an individual row
  # A row in this file should contain a tube rack barcode (orientation barcode),
  # tube location (coordinate within rack) and a tube barcode
  # i.e. Tube Rack Barcode, Tube Position, Tube Barcode
  #
  class PlateSplitToTubeRacks::CsvFile::Row
    include ActiveModel::Validations

    TUBE_LOCATION_NOT_RECOGNISED = 'contains an invalid coordinate, in %s'
    TUBE_BARCODE_MISSING = 'cannot be empty, in %s'
    TUBE_RACK_BARCODE_MISSING = 'cannot be empty, in %s'

    attr_reader :tube_rack_barcode, :tube_position, :tube_barcode, :index

    validates :tube_rack_barcode, presence: { message: ->(object, _data) { TUBE_RACK_BARCODE_MISSING % object } }
    validates :tube_position,
              inclusion: {
                in: WellHelpers.column_order,
                message: ->(object, _data) { TUBE_LOCATION_NOT_RECOGNISED % object }
              },
              unless: :empty?
    validates :tube_barcode, presence: { message: ->(object, _data) { TUBE_BARCODE_MISSING % object } }

    def initialize(index, row_data)
      @index = index
      @row_data = row_data

      # initialize supplied fields
      @tube_rack_barcode = (@row_data[0] || '').strip.upcase
      @tube_position = (@row_data[1] || '').strip.upcase
      @tube_barcode = (@row_data[2] || '').strip.upcase
    end

    def to_s
      @tube_position.present? ? "row #{index + 2} [#{@tube_position}]" : "row #{index + 2}"
    end

    def empty?
      @row_data.empty? || @row_data.compact.empty?
    end
  end
end
