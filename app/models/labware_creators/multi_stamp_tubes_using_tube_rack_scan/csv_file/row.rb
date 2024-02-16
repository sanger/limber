# frozen_string_literal: true

# Part of the Labware creator classes
module LabwareCreators
  require_dependency 'labware_creators/multi_stamp_tubes_using_tube_rack_scan/csv_file'

  #
  # Provides a simple wrapper for handling and validating an individual row
  # A row in this file should contain a tube location (coordinate within rack)
  # and a tube barcode i.e. Tube Position, Tube Barcode
  #
  class MultiStampTubesUsingTubeRackScan::CsvFile::Row
    include ActiveModel::Validations

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

    def initialize(index, row_data)
      @index = index
      @row_data = row_data

      # initialize supplied fields
      @tube_position = (@row_data[0] || '').strip.upcase
      @tube_barcode = (@row_data[1] || '').strip.upcase
    end

    def to_s
      # NB. index is zero based and no header row here
      @tube_position.present? ? "row #{index + 1} [#{@tube_position}]" : "row #{index + 1}"
    end

    def empty?
      @row_data.empty? || @row_data.compact.empty?
    end
  end
end
